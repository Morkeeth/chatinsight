import Foundation
import ArgumentParser
import MCPCore

@main
struct ChatInsightsCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chatinsights-server",
        abstract: "ChatInsights MCP Server - provides access to Messages, Contacts, Calendar, and more",
        version: "1.0.0"
    )
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose = false
    
    func run() async throws {
        if verbose {
            print("Starting ChatInsights MCP Server...", to: &standardError)
        }
        
        let server = StdioMCPServer(verbose: verbose)
        try await server.start()
    }
}

/// Stdio-based MCP Server that communicates with the main app via Bonjour
class StdioMCPServer {
    private let verbose: Bool
    private let bonjourService = BonjourService()
    private var pendingRequests: [String: CheckedContinuation<Data, Error>] = [:]
    
    init(verbose: Bool) {
        self.verbose = verbose
    }
    
    func start() async throws {
        log("Connecting to ChatInsights app via Bonjour...")
        
        // Set up Bonjour connection to app
        await setupBonjourConnection()
        
        // Wait a bit for connection to establish
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        log("Ready to receive MCP requests via stdio")
        
        // Read from stdin and forward to app
        await processStdioInput()
    }
    
    private func setupBonjourConnection() async {
        bonjourService.onConnectionEstablished = { [weak self] in
            self?.log("Connected to ChatInsights app")
        }
        
        bonjourService.onMessageReceived = { [weak self] data in
            // Forward responses from app to stdout
            self?.writeToStdout(data)
        }
        
        bonjourService.startBrowsing()
    }
    
    private func processStdioInput() async {
        let inputStream = FileHandle.standardInput
        
        while true {
            // Read line from stdin
            guard let data = try? inputStream.availableData, !data.isEmpty else {
                break
            }
            
            // Forward to app via Bonjour
            bonjourService.sendMessage(data)
        }
    }
    
    private func writeToStdout(_ data: Data) {
        FileHandle.standardOutput.write(data)
        if let string = String(data: data, encoding: .utf8), string.last != "\n" {
            FileHandle.standardOutput.write(Data("\n".utf8))
        }
    }
    
    private func log(_ message: String) {
        if verbose {
            fputs("\(message)\n", stderr)
            fflush(stderr)
        }
    }
}

// MARK: - Helper Extensions

var standardError = StandardErrorOutputStream()

struct StandardErrorOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

