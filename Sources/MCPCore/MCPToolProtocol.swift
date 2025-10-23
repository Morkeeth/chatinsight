import Foundation

/// Protocol for MCP tools
public protocol MCPToolProtocol {
    var name: String { get }
    var description: String { get }
    var inputSchema: [String: Any] { get }
    
    func execute(arguments: [String: Any]) async throws -> String
}

/// Base error for MCP tools
public enum MCPToolError: LocalizedError {
    case missingArgument(String)
    case invalidArgument(String)
    case permissionDenied(String)
    case executionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingArgument(let arg):
            return "Missing required argument: \(arg)"
        case .invalidArgument(let msg):
            return "Invalid argument: \(msg)"
        case .permissionDenied(let msg):
            return "Permission denied: \(msg)"
        case .executionFailed(let msg):
            return "Execution failed: \(msg)"
        }
    }
}

/// Helper to convert JSON-LD to formatted string
public func formatJSONLD(_ jsonLD: Any) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: jsonLD, options: [.prettyPrinted, .sortedKeys]),
          let string = String(data: data, encoding: .utf8) else {
        return "\(jsonLD)"
    }
    return string
}

/// Helper to format array of JSON-LD objects
public func formatJSONLDArray(_ items: [[String: Any]]) -> String {
    let jsonArray: [String: Any] = [
        "@context": "https://schema.org",
        "@graph": items.map { item in
            var mutable = item
            mutable.removeValue(forKey: "@context")
            return mutable
        }
    ]
    return formatJSONLD(jsonArray)
}

