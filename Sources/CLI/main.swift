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

/// Stdio-based MCP Server 
class StdioMCPServer {
    private let verbose: Bool
    
    init(verbose: Bool) {
        self.verbose = verbose
    }
    
    func start() async throws {
        log("ChatInsights MCP Server starting...")
        log("Note: Full MCP server implementation with Bonjour communication")
        log("This is a placeholder CLI that will proxy requests to the main app")
        log("Ready to receive MCP requests via stdio")
        
        // Read from stdin and process MCP protocol messages
        await processStdioInput()
    }
    
    private func processStdioInput() async {
        let inputStream = FileHandle.standardInput
        
        while true {
            // Read line from stdin
            guard let data = try? inputStream.availableData, !data.isEmpty else {
                break
            }
            
            // Parse JSON-RPC request
            if let jsonString = String(data: data, encoding: .utf8) {
                log("Received: \(jsonString)")
                
                // Send placeholder response
                let response = """
                {"jsonrpc":"2.0","id":1,"result":{"status":"ready","message":"ChatInsights MCP Server"}}
                """
                writeToStdout(Data(response.utf8))
            }
        }
    }
    
    private func writeToStdout(_ data: Data) {
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
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

