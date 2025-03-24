import Foundation

/// Cache manager for persisting data and enabling offline operation
final class CacheManager {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = CacheManager()
    
    // MARK: - Cache Types
    
    /// Types of data that can be cached
    enum CacheType: String {
        case healthMetrics = "health_metrics"
        case impactData = "impact_data"
        case lifeProjection = "life_projection"
        case userProfile = "user_profile"
        case recommendations = "recommendations"
        case studyReferences = "study_references"
    }
    
    // MARK: - Properties
    
    /// File manager for disk operations
    private let fileManager = FileManager.default
    
    /// Cache directory URL
    private let cacheDirectory: URL
    
    /// In-memory cache for fast access to recently used data
    private var memoryCache: [String: Any] = [:]
    
    /// Cache expiration times (in seconds)
    private let cacheExpirationTimes: [CacheType: TimeInterval] = [
        .healthMetrics: 3600, // 1 hour
        .impactData: 3600 * 24, // 1 day
        .lifeProjection: 3600 * 24, // 1 day
        .userProfile: 3600 * 24 * 7, // 1 week
        .recommendations: 3600 * 24 * 7, // 1 week
        .studyReferences: 3600 * 24 * 30 // 30 days
    ]
    
    // MARK: - Initialization
    
    private init() {
        // Create cache directory
        let cacheDirectoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDirectoryURL.appendingPathComponent("AmperCache", isDirectory: true)
        
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Save data to cache
    /// - Parameters:
    ///   - data: Data to save
    ///   - key: Unique identifier for the data
    ///   - type: Type of data being cached
    func saveData<T: Encodable>(_ data: T, forKey key: String, type: CacheType) {
        // 1. Save to memory cache
        memoryCache[key] = data
        
        // 2. Save to disk
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)
            
            // Add expiration time metadata
            let metadata = CacheMetadata(
                timestamp: Date(),
                expirationTime: cacheExpirationTimes[type] ?? 3600
            )
            let metadataEncoded = try encoder.encode(metadata)
            
            // Save both data and metadata
            let fileURL = getFileURL(forKey: key, type: type)
            let metadataURL = getMetadataURL(forKey: key, type: type)
            
            try encoded.write(to: fileURL)
            try metadataEncoded.write(to: metadataURL)
        } catch {
            print("Error saving to cache: \(error)")
        }
    }
    
    /// Load data from cache
    /// - Parameters:
    ///   - key: Key for the data to load
    ///   - type: Type of data to load
    /// - Returns: The cached data, or nil if not found or expired
    func loadData<T: Decodable>(forKey key: String, type: CacheType) -> T? {
        // 1. Check memory cache first
        if let cachedData = memoryCache[key] as? T {
            return cachedData
        }
        
        // 2. Check disk cache
        let fileURL = getFileURL(forKey: key, type: type)
        let metadataURL = getMetadataURL(forKey: key, type: type)
        
        // Make sure the file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check if data is expired
        if let metadata: CacheMetadata = loadMetadata(from: metadataURL), !metadata.isExpired() {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(T.self, from: data)
                
                // Update memory cache
                memoryCache[key] = decoded
                return decoded
            } catch {
                print("Error loading from cache: \(error)")
                return nil
            }
        } else {
            // Data is expired, remove it
            removeData(forKey: key, type: type)
            return nil
        }
    }
    
    /// Remove data from cache
    /// - Parameters:
    ///   - key: Key for the data to remove
    ///   - type: Type of data to remove
    func removeData(forKey key: String, type: CacheType) {
        // 1. Remove from memory cache
        memoryCache.removeValue(forKey: key)
        
        // 2. Remove from disk
        let fileURL = getFileURL(forKey: key, type: type)
        let metadataURL = getMetadataURL(forKey: key, type: type)
        
        do {
            try fileManager.removeItem(at: fileURL)
            try fileManager.removeItem(at: metadataURL)
        } catch {
            print("Error removing from cache: \(error)")
        }
    }
    
    /// Clear all cached data of a specific type
    /// - Parameter type: Type of data to clear
    func clearCache(for type: CacheType) {
        let typeDirectory = cacheDirectory.appendingPathComponent(type.rawValue, isDirectory: true)
        
        do {
            try fileManager.removeItem(at: typeDirectory)
            createDirectoryIfNeeded(at: typeDirectory)
            
            // Clear memory cache for this type
            for key in memoryCache.keys {
                if key.hasPrefix(type.rawValue) {
                    memoryCache.removeValue(forKey: key)
                }
            }
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
    
    /// Clear all cached data
    func clearAllCache() {
        do {
            try fileManager.removeItem(at: cacheDirectory)
            createCacheDirectoryIfNeeded()
            
            // Clear memory cache
            memoryCache.removeAll()
        } catch {
            print("Error clearing all cache: \(error)")
        }
    }
    
    /// Check if data exists in cache and is not expired
    /// - Parameters:
    ///   - key: Key to check
    ///   - type: Type of data to check
    /// - Returns: Whether valid data exists
    func hasValidData(forKey key: String, type: CacheType) -> Bool {
        // Check memory cache
        if memoryCache[key] != nil {
            return true
        }
        
        // Check disk cache
        let fileURL = getFileURL(forKey: key, type: type)
        let metadataURL = getMetadataURL(forKey: key, type: type)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let metadata: CacheMetadata = loadMetadata(from: metadataURL) else {
            return false
        }
        
        return !metadata.isExpired()
    }
    
    // MARK: - Private Methods
    
    /// Create the cache directory if it doesn't exist
    private func createCacheDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            
            // Create subdirectories for each cache type
            for type in CacheType.allCases {
                let typeDirectory = cacheDirectory.appendingPathComponent(type.rawValue, isDirectory: true)
                try fileManager.createDirectory(at: typeDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating cache directory: \(error)")
        }
    }
    
    /// Create a directory if it doesn't exist
    /// - Parameter url: URL of the directory to create
    private func createDirectoryIfNeeded(at url: URL) {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("Error creating directory: \(error)")
        }
    }
    
    /// Get the file URL for a cache key
    /// - Parameters:
    ///   - key: Cache key
    ///   - type: Type of data
    /// - Returns: File URL
    private func getFileURL(forKey key: String, type: CacheType) -> URL {
        let typeDirectory = cacheDirectory.appendingPathComponent(type.rawValue, isDirectory: true)
        return typeDirectory.appendingPathComponent("\(key).json")
    }
    
    /// Get the metadata URL for a cache key
    /// - Parameters:
    ///   - key: Cache key
    ///   - type: Type of data
    /// - Returns: Metadata URL
    private func getMetadataURL(forKey key: String, type: CacheType) -> URL {
        let typeDirectory = cacheDirectory.appendingPathComponent(type.rawValue, isDirectory: true)
        return typeDirectory.appendingPathComponent("\(key).metadata")
    }
    
    /// Load metadata from a URL
    /// - Parameter url: URL to load from
    /// - Returns: The loaded metadata, or nil if not found
    private func loadMetadata<T: Decodable>(from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error loading metadata: \(error)")
            return nil
        }
    }
}

// MARK: - Support Types

/// Metadata for cached items
struct CacheMetadata: Codable {
    let timestamp: Date
    let expirationTime: TimeInterval
    
    /// Check if the cached item is expired
    func isExpired() -> Bool {
        let expirationDate = timestamp.addingTimeInterval(expirationTime)
        return Date() > expirationDate
    }
}

// MARK: - CacheType Extension

extension CacheManager.CacheType: CaseIterable {} 