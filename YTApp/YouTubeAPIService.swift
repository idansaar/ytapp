import Foundation

// MARK: - YouTube API Models

// For direct channel queries (/channels endpoint)
struct YouTubeChannelResponse: Codable {
    let items: [YouTubeChannelItem]
}

struct YouTubeChannelItem: Codable {
    let id: String
    let snippet: YouTubeChannelSnippet
    let statistics: YouTubeChannelStatistics?
}

// For channel search queries (/search endpoint)
struct YouTubeChannelSearchResponse: Codable {
    let items: [YouTubeChannelSearchItem]
}

struct YouTubeChannelSearchItem: Codable {
    let id: YouTubeChannelSearchId
    let snippet: YouTubeChannelSnippet
}

struct YouTubeChannelSearchId: Codable {
    let channelId: String
}

struct YouTubeChannelSnippet: Codable {
    let title: String
    let description: String
    let customUrl: String?
    let thumbnails: YouTubeThumbnails
    let channelId: String?
    let channelTitle: String?
}

struct YouTubeChannelStatistics: Codable {
    let subscriberCount: String?
    let videoCount: String?
}

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchVideoItem]
    let nextPageToken: String?
}

struct YouTubeVideosResponse: Codable {
    let items: [YouTubeVideoItem]
    let nextPageToken: String?
}

struct YouTubeVideoItem: Codable {
    let id: String  // For videos endpoint, id is a string
    let snippet: YouTubeVideoSnippet?  // Optional because video details API doesn't include snippet
    let contentDetails: YouTubeVideoContentDetails?
    let statistics: YouTubeVideoStatistics?
}

struct YouTubeSearchVideoItem: Codable {
    let id: YouTubeVideoId  // For search endpoint, id is an object
    let snippet: YouTubeVideoSnippet
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubeVideoSnippet: Codable {
    let title: String
    let description: String
    let publishedAt: String
    let channelId: String
    let channelTitle: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeVideoContentDetails: Codable {
    let duration: String
}

struct YouTubeVideoStatistics: Codable {
    let viewCount: String?
    let likeCount: String?
}

struct YouTubeThumbnails: Codable {
    let `default`: YouTubeThumbnail?
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
    let standard: YouTubeThumbnail?
    let maxres: YouTubeThumbnail?
}

struct YouTubeThumbnail: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

// MARK: - YouTube API Service

class YouTubeAPIService: ObservableObject {
    static let shared = YouTubeAPIService()
    
    private let baseURL = Config.youtubeAPIBaseURL
    private let session = URLSession.shared
    private let apiKey = Config.youtubeAPIKey
    
    private init() {}
    
    // MARK: - Configuration Check
    
    private func validateAPIKey() throws {
        guard !Config.shouldUseMockData else {
            // Skip validation when using mock data
            return
        }
        
        guard Config.isYouTubeAPIConfigured else {
            throw YouTubeAPIError.apiKeyMissing
        }
    }
    
    // MARK: - Channel Methods
    
    func searchChannelByName(_ name: String) async throws -> [Channel] {
        try validateAPIKey()
        
        // Return mock data if configured
        if Config.shouldUseMockData {
            return createMockChannels(for: name)
        }
        
        print("🔍 Searching YouTube API for channels with name: \(name)")
        
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "\(baseURL)/search?part=snippet&type=channel&q=\(encodedName)&key=\(apiKey)&maxResults=\(Config.maxChannelSearchResults)"
        
        print("🌐 API URL: \(urlString.replacingOccurrences(of: apiKey, with: "***"))")
        
        guard let url = URL(string: urlString) else {
            throw YouTubeAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError.invalidResponse
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorData)")
            }
            throw YouTubeAPIError.invalidResponse
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(YouTubeChannelSearchResponse.self, from: data)
            print("✅ Successfully decoded \(searchResponse.items.count) channels")
            
            let channels = searchResponse.items.map { item in
                Channel(
                    id: item.id.channelId,
                    name: item.snippet.title,
                    handle: item.snippet.customUrl.map { "@\($0)" },
                    thumbnailURL: item.snippet.thumbnails.medium?.url,
                    description: item.snippet.description
                )
            }
            
            for channel in channels {
                print("📺 Found channel: \(channel.name) (ID: \(channel.id))")
            }
            
            return channels
        } catch {
            print("❌ JSON Decoding Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON Response: \(jsonString)")
            }
            throw error
        }
    }
    
    func getChannelFromURL(_ urlString: String) async throws -> Channel {
        // First try to extract direct channel ID
        if let channelId = try? extractChannelIdFromURL(urlString) {
            return try await getChannelById(channelId)
        }
        
        // If that fails, try to resolve handle or custom URL
        return try await resolveChannelFromURL(urlString)
    }
    
    func getChannelById(_ channelId: String) async throws -> Channel {
        try validateAPIKey()
        
        // Return mock data if configured
        if Config.shouldUseMockData {
            return createMockChannel(id: channelId)
        }
        
        let urlString = "\(baseURL)/channels?part=snippet,statistics&id=\(channelId)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw YouTubeAPIError.invalidResponse
        }
        
        let channelResponse = try JSONDecoder().decode(YouTubeChannelResponse.self, from: data)
        
        guard let item = channelResponse.items.first else {
            throw YouTubeAPIError.channelNotFound
        }
        
        return Channel(
            id: item.id,
            name: item.snippet.title,
            handle: item.snippet.customUrl.map { "@\($0)" },
            thumbnailURL: item.snippet.thumbnails.medium?.url,
            subscriberCount: item.statistics?.subscriberCount.map { formatSubscriberCount($0) },
            description: item.snippet.description
        )
    }
    
    // MARK: - Video Methods
    
    func getChannelVideos(channelId: String, lookbackDays: Int = 7, maxResults: Int = 50) async throws -> [ChannelVideo] {
        try validateAPIKey()
        
        // Return mock data if configured
        if Config.shouldUseMockData {
            return createMockVideos(for: channelId, lookbackDays: lookbackDays, maxResults: maxResults)
        }
        
        print("🎥 Fetching videos for channel ID: \(channelId)")
        
        // Calculate the date for lookback
        let calendar = Calendar.current
        let lookbackDate = calendar.date(byAdding: .day, value: -lookbackDays, to: Date()) ?? Date()
        let dateFormatter = ISO8601DateFormatter()
        let publishedAfter = dateFormatter.string(from: lookbackDate)
        
        print("📅 Looking for videos published after: \(publishedAfter)")
        
        let urlString = "\(baseURL)/search?part=snippet&channelId=\(channelId)&type=video&order=date&publishedAfter=\(publishedAfter)&maxResults=\(maxResults)&key=\(apiKey)"
        
        print("🌐 Video API URL: \(urlString.replacingOccurrences(of: apiKey, with: "***"))")
        
        guard let url = URL(string: urlString) else {
            throw YouTubeAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError.invalidResponse
        }
        
        print("📡 Video HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ Video API Error Response: \(errorData)")
            }
            throw YouTubeAPIError.invalidResponse
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            print("✅ Successfully decoded \(searchResponse.items.count) video search results")
            
            // Get additional video details (duration, statistics)
            let videoIds = searchResponse.items.map { $0.id.videoId }
            print("🔍 Getting details for video IDs: \(videoIds)")
            
            let videoDetails = try await getVideoDetails(videoIds: videoIds)
            print("📊 Got details for \(videoDetails.count) videos")
            
            var channelVideos: [ChannelVideo] = []
            for (index, item) in searchResponse.items.enumerated() {
                print("🎬 Processing video \(index + 1): \(item.snippet.title)")
                
                let videoDetail = videoDetails.first { $0.id == item.id.videoId }
                
                let id: String = item.id.videoId
                let title: String = item.snippet.title
                let channelID: String = item.snippet.channelId
                let channelName: String = item.snippet.channelTitle
                let publishedAt: Date = parseDate(item.snippet.publishedAt) ?? Date()
                let thumbnailURL: String? = item.snippet.thumbnails.medium?.url
                
                var duration: String? = nil
                if let d = videoDetail?.contentDetails?.duration {
                    duration = formatDuration(d)
                    print("⏱️ Video duration: \(duration!)")
                }
                
                var viewCount: String? = nil
                if let vc = videoDetail?.statistics?.viewCount {
                    viewCount = formatViewCount(vc)
                    print("👁️ View count: \(viewCount!)")
                }

                let channelVideo = ChannelVideo(
                    id: id,
                    title: title,
                    channelID: channelID,
                    channelName: channelName,
                    publishedAt: publishedAt,
                    thumbnailURL: thumbnailURL,
                    duration: duration,
                    viewCount: viewCount
                )
                channelVideos.append(channelVideo)
                print("✅ Added video: \(title)")
            }
            
            print("✅ Successfully created \(channelVideos.count) channel videos")
            return channelVideos
        } catch {
            print("❌ Video JSON Decoding Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw Video JSON Response: \(jsonString)")
            }
            throw error
        }
    }
    
    private func getVideoDetails(videoIds: [String]) async throws -> [YouTubeVideoItem] {
        guard !videoIds.isEmpty else { 
            print("⚠️ No video IDs provided for details")
            return [] 
        }
        
        print("🔍 Getting video details for \(videoIds.count) videos")
        
        let idsString = videoIds.joined(separator: ",")
        let urlString = "\(baseURL)/videos?part=contentDetails,statistics&id=\(idsString)&key=\(apiKey)"
        
        print("🌐 Video Details API URL: \(urlString.replacingOccurrences(of: apiKey, with: "***"))")
        
        guard let url = URL(string: urlString) else {
            throw YouTubeAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError.invalidResponse
        }
        
        print("📡 Video Details HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ Video Details API Error Response: \(errorData)")
            }
            throw YouTubeAPIError.invalidResponse
        }
        
        do {
            let videosResponse = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
            print("✅ Successfully decoded \(videosResponse.items.count) video details")
            return videosResponse.items
        } catch {
            print("❌ Video Details JSON Decoding Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw Video Details JSON Response: \(jsonString)")
            }
            throw error
        }
    }
    
    private func resolveChannelFromURL(_ urlString: String) async throws -> Channel {
        print("🔄 Resolving channel from URL: \(urlString)")
        
        // Clean the URL and extract the handle or custom name
        let cleanURL = urlString.components(separatedBy: "?").first ?? urlString
        print("🧹 Cleaned URL: \(cleanURL)")
        
        guard let url = URL(string: cleanURL) else {
            print("❌ Invalid URL format")
            throw YouTubeAPIError.invalidURL
        }
        
        let path = url.path
        print("📍 URL path: \(path)")
        
        var searchQuery: String?
        
        if path.contains("/@") {
            // Extract handle from @channelhandle format
            let components = path.components(separatedBy: "/@")
            if components.count > 1 {
                searchQuery = components[1]
                print("🎯 Extracted handle: @\(searchQuery!)")
            }
        } else if path.contains("/c/") {
            // Extract custom name from /c/CustomName format
            let components = path.components(separatedBy: "/c/")
            if components.count > 1 {
                searchQuery = components[1]
                print("🎯 Extracted custom name: \(searchQuery!)")
            }
        } else if path.contains("/user/") {
            // Extract username from /user/Username format
            let components = path.components(separatedBy: "/user/")
            if components.count > 1 {
                searchQuery = components[1]
                print("🎯 Extracted username: \(searchQuery!)")
            }
        }
        
        guard let query = searchQuery, !query.isEmpty else {
            print("❌ Could not extract channel identifier from URL")
            throw YouTubeAPIError.invalidChannelURL
        }
        
        print("🔍 Searching for channel with query: \(query)")
        
        // Search for the channel by name/handle
        let channels = try await searchChannelByName(query)
        print("📊 Found \(channels.count) channels")
        
        // Return the first match (most relevant)
        guard let channel = channels.first else {
            print("❌ No channels found for query: \(query)")
            throw YouTubeAPIError.channelNotFound
        }
        
        print("✅ Resolved to channel: \(channel.name) (ID: \(channel.id))")
        return channel
    }

    // MARK: - Helper Methods
    
    private func extractChannelIdFromURL(_ urlString: String) throws -> String {
        guard let url = URL(string: urlString) else {
            throw YouTubeAPIError.invalidURL
        }
        
        let path = url.path
        
        // Handle direct channel ID URLs only
        if path.contains("/channel/") {
            // https://youtube.com/channel/UCxxxxx
            let components = path.components(separatedBy: "/channel/")
            if components.count > 1 {
                return components[1].components(separatedBy: "/").first ?? ""
            }
        }
        
        // For all other formats, we'll use the resolve method
        throw YouTubeAPIError.unsupportedURLFormat
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    private func formatDuration(_ duration: String) -> String {
        // Parse ISO 8601 duration format (PT4M13S -> 4:13)
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = duration as NSString
        let results = regex?.firstMatch(in: duration, range: NSRange(location: 0, length: nsString.length))
        
        var hours = 0
        var minutes = 0
        var seconds = 0
        
        if let results = results {
            if results.range(at: 1).location != NSNotFound {
                hours = Int(nsString.substring(with: results.range(at: 1))) ?? 0
            }
            if results.range(at: 2).location != NSNotFound {
                minutes = Int(nsString.substring(with: results.range(at: 2))) ?? 0
            }
            if results.range(at: 3).location != NSNotFound {
                seconds = Int(nsString.substring(with: results.range(at: 3))) ?? 0
            }
        }
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatViewCount(_ viewCount: String) -> String {
        guard let count = Int(viewCount) else { return viewCount }
        
        if count >= 1_000_000 {
            return String(format: "%.1fM views", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK views", Double(count) / 1_000)
        } else {
            return "\(count) views"
        }
    }
    
    private func formatSubscriberCount(_ subscriberCount: String) -> String {
        guard let count = Int(subscriberCount) else { return subscriberCount }
        
        if count >= 1_000_000 {
            return String(format: "%.1fM subscribers", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK subscribers", Double(count) / 1_000)
        } else {
            return "\(count) subscribers"
        }
    }
}

// MARK: - Error Types

enum YouTubeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case channelNotFound
    case invalidChannelURL
    case unsupportedURLFormat
    case apiKeyMissing
    case quotaExceeded
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid response from YouTube API"
        case .channelNotFound:
            return "Channel not found"
        case .invalidChannelURL:
            return "Invalid YouTube channel URL"
        case .unsupportedURLFormat:
            return "Unsupported YouTube URL format"
        case .apiKeyMissing:
            return "YouTube API key is missing"
        case .quotaExceeded:
            return "YouTube API quota exceeded"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Data for Testing

extension YouTubeAPIService {
    
    private func createMockChannels(for query: String) -> [Channel] {
        // Create mock channels based on the search query
        let mockChannels = [
            Channel(
                id: "UC_mock_\(query.hashValue)",
                name: query.capitalized,
                handle: "@\(query.lowercased())",
                thumbnailURL: "https://via.placeholder.com/240x240",
                subscriberCount: "1.2M",
                description: "Mock channel for \(query). This is sample data for testing without YouTube API key."
            ),
            Channel(
                id: "UC_mock2_\(query.hashValue)",
                name: "\(query.capitalized) Official",
                handle: "@\(query.lowercased())official",
                thumbnailURL: "https://via.placeholder.com/240x240",
                subscriberCount: "856K",
                description: "Official mock channel for \(query). Sample data for development."
            )
        ]
        
        return Array(mockChannels.prefix(Config.maxChannelSearchResults))
    }
    
    private func createMockChannel(id: String) -> Channel {
        return Channel(
            id: id,
            name: "Mock Channel \(id.suffix(8))",
            handle: "@mockchannel",
            thumbnailURL: "https://via.placeholder.com/240x240",
            subscriberCount: "500K",
            description: "This is a mock channel for testing purposes. Replace with real YouTube API key for actual data."
        )
    }
    
    private func createMockVideos(for channelId: String, lookbackDays: Int, maxResults: Int) -> [ChannelVideo] {
        let calendar = Calendar.current
        var mockVideos: [ChannelVideo] = []
        
        // Create mock videos for the past few days
        for i in 0..<min(maxResults, 10) {
            let daysAgo = Int.random(in: 0...lookbackDays)
            let publishDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            let video = ChannelVideo(
                id: "mock_video_\(channelId)_\(i)",
                title: "Mock Video \(i + 1): Sample Content for Testing",
                channelID: channelId,
                channelName: "Mock Channel",
                publishedAt: publishDate,
                thumbnailURL: "https://via.placeholder.com/320x180",
                duration: "\(Int.random(in: 2...15)):\(String(format: "%02d", Int.random(in: 0...59)))",
                viewCount: "\(Int.random(in: 1...999))K"
            )
            
            mockVideos.append(video)
        }
        
        return mockVideos.sorted { $0.publishedAt > $1.publishedAt }
    }
}
