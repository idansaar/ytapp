import Foundation

struct Channel: Codable, Identifiable, Equatable, Hashable {
    var id: String // Channel ID from YouTube
    var name: String
    var handle: String? // @channelhandle
    var thumbnailURL: String?
    var subscriberCount: String?
    var description: String?
    var dateAdded: Date
    var lastUpdated: Date
    var lookbackDays: Int // Configurable lookback period for videos
    var isActive: Bool // Whether to fetch updates for this channel
    
    init(id: String, name: String, handle: String? = nil, thumbnailURL: String? = nil, subscriberCount: String? = nil, description: String? = nil, lookbackDays: Int = 7, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.handle = handle
        self.thumbnailURL = thumbnailURL
        self.subscriberCount = subscriberCount
        self.description = description
        self.dateAdded = Date()
        self.lastUpdated = Date()
        self.lookbackDays = lookbackDays
        self.isActive = isActive
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ChannelVideo: Codable, Identifiable, Equatable, Hashable {
    var id: String // Video ID
    var title: String
    var channelID: String
    var channelName: String
    var publishedAt: Date
    var thumbnailURL: String?
    var duration: String?
    var viewCount: String?
    var isWatched: Bool
    var watchedAt: Date?
    
    init(id: String, title: String, channelID: String, channelName: String, publishedAt: Date, thumbnailURL: String? = nil, duration: String? = nil, viewCount: String? = nil, isWatched: Bool = false, watchedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.channelID = channelID
        self.channelName = channelName
        self.publishedAt = publishedAt
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.viewCount = viewCount
        self.isWatched = isWatched
        self.watchedAt = watchedAt
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class ChannelsManager: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var channelVideos: [String: [ChannelVideo]] = [:] // channelID -> videos
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let channelsKey = "subscribedChannels"
    private let channelVideosKey = "channelVideos"
    
    init() {
        loadChannels()
        loadChannelVideos()
    }
    
    // MARK: - Channel Management
    
    func addChannel(_ channel: Channel) {
        print("📺 Adding channel: \(channel.name) (ID: \(channel.id))")
        
        // Check if channel already exists
        if !channels.contains(where: { $0.id == channel.id }) {
            channels.insert(channel, at: 0)
            saveChannels()
            print("✅ Channel added successfully. Total channels: \(channels.count)")
            
            // Fetch initial videos for this channel
            fetchChannelVideos(for: channel)
        } else {
            print("⚠️ Channel already exists: \(channel.name)")
            errorMessage = "Channel '\(channel.name)' is already added"
        }
    }
    
    func removeChannel(at offsets: IndexSet) {
        for index in offsets {
            let channel = channels[index]
            print("🗑️ Removing channel: \(channel.name)")
            
            // Remove channel videos
            channelVideos.removeValue(forKey: channel.id)
        }
        
        channels.remove(atOffsets: offsets)
        saveChannels()
        saveChannelVideos()
    }
    
    func removeChannel(channelID: String) {
        channels.removeAll { $0.id == channelID }
        channelVideos.removeValue(forKey: channelID)
        saveChannels()
        saveChannelVideos()
    }
    
    func updateChannel(_ channel: Channel) {
        if let index = channels.firstIndex(where: { $0.id == channel.id }) {
            channels[index] = channel
            saveChannels()
        }
    }
    
    func toggleChannelActive(channelID: String) {
        if let index = channels.firstIndex(where: { $0.id == channelID }) {
            channels[index].isActive.toggle()
            saveChannels()
        }
    }
    
    func updateChannelLookback(channelID: String, days: Int) {
        if let index = channels.firstIndex(where: { $0.id == channelID }) {
            channels[index].lookbackDays = days
            channels[index].lastUpdated = Date()
            saveChannels()
            
            // Refresh videos for this channel with new lookback period
            fetchChannelVideos(for: channels[index])
        }
    }
    
    // MARK: - Video Management
    
    func markVideoAsWatched(videoID: String) {
        for (channelID, videos) in channelVideos {
            if let videoIndex = videos.firstIndex(where: { $0.id == videoID }) {
                channelVideos[channelID]?[videoIndex].isWatched = true
                channelVideos[channelID]?[videoIndex].watchedAt = Date()
                saveChannelVideos()
                print("✅ Marked video as watched: \(videoID)")
                break
            }
        }
    }
    
    func getUnwatchedVideosCount(for channelID: String) -> Int {
        return channelVideos[channelID]?.filter { !$0.isWatched }.count ?? 0
    }
    
    func getAllUnwatchedVideos() -> [ChannelVideo] {
        var allUnwatched: [ChannelVideo] = []
        for videos in channelVideos.values {
            allUnwatched.append(contentsOf: videos.filter { !$0.isWatched })
        }
        return allUnwatched.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    func getVideosForChannel(_ channelID: String) -> [ChannelVideo] {
        return channelVideos[channelID] ?? []
    }
    
    // MARK: - Data Fetching (Placeholder Implementation)
    
    func fetchChannelVideos(for channel: Channel) {
        print("🔄 Fetching videos for channel: \(channel.name)")
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual YouTube API integration
        // For now, create mock data for demonstration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.createMockVideos(for: channel)
            self.isLoading = false
        }
    }
    
    func refreshAllChannels() {
        print("🔄 Refreshing all active channels")
        isLoading = true
        errorMessage = nil
        
        let activeChannels = channels.filter { $0.isActive }
        
        for channel in activeChannels {
            fetchChannelVideos(for: channel)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
        }
    }
    
    // MARK: - Mock Data (Temporary)
    
    private func createMockVideos(for channel: Channel) {
        let mockVideos = [
            ChannelVideo(
                id: "\(channel.id)_video_1",
                title: "Latest Video from \(channel.name)",
                channelID: channel.id,
                channelName: channel.name,
                publishedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                duration: "10:30",
                viewCount: "1.2K views"
            ),
            ChannelVideo(
                id: "\(channel.id)_video_2",
                title: "Previous Video from \(channel.name)",
                channelID: channel.id,
                channelName: channel.name,
                publishedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                duration: "15:45",
                viewCount: "5.8K views"
            ),
            ChannelVideo(
                id: "\(channel.id)_video_3",
                title: "Older Video from \(channel.name)",
                channelID: channel.id,
                channelName: channel.name,
                publishedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                duration: "8:20",
                viewCount: "3.1K views"
            )
        ]
        
        channelVideos[channel.id] = mockVideos
        saveChannelVideos()
        print("✅ Mock videos created for channel: \(channel.name)")
    }
    
    // MARK: - Persistence
    
    private func saveChannels() {
        if let encoded = try? JSONEncoder().encode(channels) {
            UserDefaults.standard.set(encoded, forKey: channelsKey)
        }
    }
    
    private func loadChannels() {
        if let data = UserDefaults.standard.data(forKey: channelsKey),
           let decoded = try? JSONDecoder().decode([Channel].self, from: data) {
            channels = decoded
        }
    }
    
    private func saveChannelVideos() {
        if let encoded = try? JSONEncoder().encode(channelVideos) {
            UserDefaults.standard.set(encoded, forKey: channelVideosKey)
        }
    }
    
    private func loadChannelVideos() {
        if let data = UserDefaults.standard.data(forKey: channelVideosKey),
           let decoded = try? JSONDecoder().decode([String: [ChannelVideo]].self, from: data) {
            channelVideos = decoded
        }
    }
    
    // MARK: - Utility Methods
    
    func clearAllChannels() {
        channels.removeAll()
        channelVideos.removeAll()
        saveChannels()
        saveChannelVideos()
        print("🗑️ All channels cleared")
    }
    
    func getChannelByID(_ channelID: String) -> Channel? {
        return channels.first { $0.id == channelID }
    }
    
    func getTotalUnwatchedCount() -> Int {
        return channelVideos.values.flatMap { $0 }.filter { !$0.isWatched }.count
    }
}
