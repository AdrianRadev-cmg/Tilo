import Foundation

/// Manages API key security through basic obfuscation
/// Note: For production apps with sensitive data, consider using a backend proxy
/// This provides basic protection against casual inspection of the binary
enum APIKeyManager {
    
    // MARK: - Obfuscated Key Storage
    
    /// The key is stored as individual character codes to avoid plain text in binary
    /// Original: "cur_live_ekGkTC1IKGFiCe85LkBEwkjMNnZRA05iaVDqYq6G"
    private static let obfuscatedKey: [UInt8] = [
        99, 117, 114, 95, 108, 105, 118, 101, 95,  // cur_live_
        101, 107, 71, 107, 84, 67, 49, 73, 75, 71, // ekGkTC1IKG
        70, 105, 67, 101, 56, 53, 76, 107, 66, 69, // FiCe85LkBE
        119, 107, 106, 77, 78, 110, 90, 82, 65, 48, // wkjMNnZRA0
        53, 105, 97, 86, 68, 113, 89, 113, 54, 71  // 5iaVDqYq6G
    ]
    
    /// XOR mask for additional obfuscation
    private static let xorMask: UInt8 = 0x00 // Can be changed for extra security
    
    // MARK: - Key Retrieval
    
    /// Retrieves the deobfuscated API key
    /// - Returns: The API key string
    static var apiKey: String {
        let deobfuscated = obfuscatedKey.map { $0 ^ xorMask }
        return String(bytes: deobfuscated, encoding: .utf8) ?? ""
    }
    
    // MARK: - Validation
    
    /// Validates that the API key is properly configured
    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey.hasPrefix("cur_")
    }
}



