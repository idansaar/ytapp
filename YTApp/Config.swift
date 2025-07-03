import Foundation

struct Config {
    // MARK: - YouTube API Configuration
    
    /// YouTube Data API v3 Key
    /// Get your API key from: https://console.developers.google.com/
    /// 1. Create a new project or select existing
    /// 2. Enable YouTube Data API v3
    /// 3. Create credentials (API Key)
    /// 4. Replace the value below with your actual API key
    /// 
    /// ✅ API Key configured for real YouTube data
    static let youtubeAPIKey = "AIzaSyC87Q7zTIupfxtGMbAmconErnqeAAvdcIg"
    
    // MARK: - Development Configuration
    
    /// Set to true to use mock data for testing without API key
    /// Set to false to use real YouTube API (requires valid API key)
    /// ✅ Using real YouTube API data
    static let useMockData = false
    
    // MARK: - API Configuration
    
    static let youtubeAPIBaseURL = "https://www.googleapis.com/youtube/v3"
    
    // MARK: - App Configuration
    
    static let defaultLookbackDays = 7
    static let maxVideosPerChannel = 50
    static let maxChannelSearchResults = 10
    
    // MARK: - Validation
    
    static var isYouTubeAPIConfigured: Bool {
        return !youtubeAPIKey.isEmpty && youtubeAPIKey != "YOUR_YOUTUBE_API_KEY_HERE"
    }
    
    static var shouldUseMockData: Bool {
        return useMockData || !isYouTubeAPIConfigured
    }
    
    static func validateConfiguration() -> String? {
        if !isYouTubeAPIConfigured && !useMockData {
            return """
            ⚠️ YouTube API key is not configured.
            
            To use real YouTube data:
            1. Go to https://console.cloud.google.com/
            2. Create a project and enable YouTube Data API v3
            3. Create an API key
            4. Replace 'YOUR_YOUTUBE_API_KEY_HERE' in Config.swift with your actual key
            
            Example: static let youtubeAPIKey = "AIzaSyC-your-actual-api-key-here"
            
            Or set useMockData = true to test with sample data.
            """
        }
        return nil
    }
}
