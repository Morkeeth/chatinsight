import Foundation

/// Decoder for Apple's proprietary typedstream format used in iMessage
/// Adapted from iMCP's Madrid package and imessage-exporter
class TypedstreamDecoder {
    private let data: Data
    private var position: Int = 0
    
    init(data: Data) {
        self.data = data
    }
    
    func decodeText() -> String? {
        // Reset position
        position = 0
        
        // Check for typedstream header
        guard data.count > 8 else { return nil }
        
        // Look for NSAttributedString markers
        var text = ""
        var currentPosition = 0
        
        while currentPosition < data.count - 1 {
            // Look for text sequences
            // Try to find readable UTF-8 strings
            if let string = extractString(at: currentPosition) {
                if !string.isEmpty && string.count > 1 {
                    text += string
                }
            }
            currentPosition += 1
        }
        
        return text.isEmpty ? nil : text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractString(at position: Int) -> String? {
        guard position < data.count else { return nil }
        
        var stringBytes = [UInt8]()
        var currentPos = position
        
        // Extract sequence of printable characters
        while currentPos < data.count {
            let byte = data[currentPos]
            
            // Check if it's a printable ASCII or UTF-8 continuation
            if (byte >= 0x20 && byte <= 0x7E) || (byte >= 0x80 && byte <= 0xBF) || (byte >= 0xC0 && byte <= 0xFD) {
                stringBytes.append(byte)
                currentPos += 1
            } else if !stringBytes.isEmpty {
                break
            } else {
                return nil
            }
            
            // Limit string extraction length
            if stringBytes.count > 1000 {
                break
            }
        }
        
        // Try to decode as UTF-8
        if stringBytes.count > 1 {
            return String(bytes: stringBytes, encoding: .utf8)
        }
        
        return nil
    }
    
    /// Simplified decoder that attempts to extract plain text from attributedBody
    static func decode(attributedBody: Data) -> String? {
        let decoder = TypedstreamDecoder(data: attributedBody)
        return decoder.decodeText()
    }
}

// MARK: - Alternative NSKeyedUnarchiver approach for newer messages
extension TypedstreamDecoder {
    static func decodeWithUnarchiver(data: Data) -> String? {
        do {
            // Try NSKeyedUnarchiver for newer format messages
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            
            if let attributedString = try? unarchiver.decodeTopLevelObject(
                of: NSAttributedString.self,
                forKey: NSKeyedArchiveRootObjectKey
            ) {
                return attributedString.string
            }
            
            // Fallback to any string object
            if let string = try? unarchiver.decodeTopLevelObject(
                of: NSString.self,
                forKey: NSKeyedArchiveRootObjectKey
            ) as? String {
                return string
            }
        } catch {
            // If NSKeyedUnarchiver fails, try typedstream decoder
            return decode(attributedBody: data)
        }
        
        return nil
    }
}

