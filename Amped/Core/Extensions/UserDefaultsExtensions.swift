import Foundation

/// Extensions for UserDefaults to provide additional functionality
extension UserDefaults {
    /// Get a boolean value with a default fallback
    /// - Parameters:
    ///   - key: The key to look up in UserDefaults
    ///   - defaultValue: The default value to return if the key doesn't exist
    /// - Returns: The stored boolean value or the default if the key doesn't exist
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return self.bool(forKey: key)
    }
    
    /// Get an integer value with a default fallback
    /// - Parameters:
    ///   - key: The key to look up in UserDefaults
    ///   - defaultValue: The default value to return if the key doesn't exist
    /// - Returns: The stored integer value or the default if the key doesn't exist
    func integer(forKey key: String, defaultValue: Int) -> Int {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return self.integer(forKey: key)
    }
    
    /// Get a double value with a default fallback
    /// - Parameters:
    ///   - key: The key to look up in UserDefaults
    ///   - defaultValue: The default value to return if the key doesn't exist
    /// - Returns: The stored double value or the default if the key doesn't exist
    func double(forKey key: String, defaultValue: Double) -> Double {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return self.double(forKey: key)
    }
    
    /// Get a string value with a default fallback
    /// - Parameters:
    ///   - key: The key to look up in UserDefaults
    ///   - defaultValue: The default value to return if the key doesn't exist
    /// - Returns: The stored string value or the default if the key doesn't exist
    func string(forKey key: String, defaultValue: String) -> String {
        return self.string(forKey: key) ?? defaultValue
    }
} 