import Foundation
import Network

/// Bonjour service for MCP server discovery and communication
public class BonjourService: NSObject {
    private let serviceType = "_mcp._tcp"
    private let serviceName: String
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    
    public var onMessageReceived: ((Data) -> Void)?
    public var onConnectionEstablished: (() -> Void)?
    
    public init(serviceName: String = "ChatInsightsMCP") {
        self.serviceName = serviceName
        super.init()
    }
    
    // MARK: - Server (App Side)
    
    /// Start advertising the MCP service
    public func startAdvertising(port: UInt16 = 0) throws {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        // Set up Bonjour service
        let listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
        
        listener.service = NWListener.Service(
            name: serviceName,
            type: serviceType
        )
        
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let port = listener.port {
                    print("✓ MCP Service advertising on port \(port)")
                }
            case .failed(let error):
                print("✗ Listener failed: \(error)")
            case .cancelled:
                print("✓ Listener cancelled")
            default:
                break
            }
        }
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        listener.start(queue: .main)
        self.listener = listener
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        print("✓ New connection from CLI")
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✓ Connection ready")
                self?.onConnectionEstablished?()
                self?.receiveMessage(on: connection)
            case .failed(let error):
                print("✗ Connection failed: \(error)")
            case .cancelled:
                print("✓ Connection cancelled")
            default:
                break
            }
        }
        
        connection.start(queue: .main)
        self.connection = connection
    }
    
    private func receiveMessage(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.onMessageReceived?(data)
            }
            
            if let error = error {
                print("✗ Receive error: \(error)")
                return
            }
            
            if !isComplete {
                self?.receiveMessage(on: connection)
            }
        }
    }
    
    public func sendMessage(_ data: Data) {
        guard let connection = connection else {
            print("✗ No connection to send message")
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("✗ Send error: \(error)")
            }
        })
    }
    
    public func stopAdvertising() {
        listener?.cancel()
        listener = nil
        connection?.cancel()
        connection = nil
    }
    
    // MARK: - Client (CLI Side)
    
    /// Browse for MCP services
    public func startBrowsing() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: parameters)
        
        browser.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("✓ Browser ready")
            case .failed(let error):
                print("✗ Browser failed: \(error)")
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            for result in results {
                if case .service(let name, let type, let domain, _) = result.endpoint {
                    if name == self?.serviceName {
                        print("✓ Found MCP service: \(name)")
                        self?.connectTo(result.endpoint)
                        return
                    }
                }
            }
        }
        
        browser.start(queue: .main)
        self.browser = browser
    }
    
    private func connectTo(_ endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✓ Connected to MCP service")
                self?.onConnectionEstablished?()
                self?.receiveMessage(on: connection)
            case .failed(let error):
                print("✗ Connection failed: \(error)")
            case .cancelled:
                print("✓ Connection cancelled")
            default:
                break
            }
        }
        
        connection.start(queue: .main)
        self.connection = connection
    }
    
    public func stopBrowsing() {
        browser?.cancel()
        browser = nil
        connection?.cancel()
        connection = nil
    }
}

/// Message protocol for MCP communication
public struct MCPMessage: Codable {
    public let id: String
    public let method: String
    public let params: [String: AnyCodable]?
    
    public init(id: String = UUID().uuidString, method: String, params: [String: AnyCodable]? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct MCPResponse: Codable {
    public let id: String
    public let result: AnyCodable?
    public let error: MCPError?
    
    public init(id: String, result: AnyCodable? = nil, error: MCPError? = nil) {
        self.id = id
        self.result = result
        self.error = error
    }
}

public struct MCPError: Codable {
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

/// Type-erased Codable wrapper
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

