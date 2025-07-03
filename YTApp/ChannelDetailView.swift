import SwiftUI

struct ChannelDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let channel: Channel
    let channelsManager: ChannelsManager
    let favoritesManager: FavoritesManager
    let onVideoPlay: ((String) -> Void)?
    
    @State private var videos: [ChannelVideo] = []
    @State private var showingSettings = false
    @State private var isRefreshing = false
    
    init(channel: Channel, channelsManager: ChannelsManager, favoritesManager: FavoritesManager, onVideoPlay: ((String) -> Void)? = nil) {
        self.channel = channel
        self.channelsManager = channelsManager
        self.favoritesManager = favoritesManager
        self.onVideoPlay = onVideoPlay
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Channel header
                channelHeaderView
                    .padding()
                    .background(Color(.systemGray6))
                
                // Videos list
                if videos.isEmpty {
                    emptyVideosView
                } else {
                    videosListView
                }
            }
            .navigationTitle(channel.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            refreshVideos()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .disabled(isRefreshing)
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onAppear {
                loadVideos()
            }
            .sheet(isPresented: $showingSettings) {
                ChannelSettingsView(channel: channel, channelsManager: channelsManager)
            }
        }
    }
    
    // MARK: - Channel Header
    
    private var channelHeaderView: some View {
        HStack(spacing: 16) {
            // Channel thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "tv")
                        .foregroundColor(.gray)
                        .font(.title)
                )
            
            // Channel info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(channel.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    if !channel.isActive {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                if let handle = channel.handle {
                    Text(handle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let subscriberCount = channel.subscriberCount {
                    Text(subscriberCount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lookback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(channel.lookbackDays) days")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unwatched")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(channelsManager.getUnwatchedVideosCount(for: channel.id))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Empty Videos View
    
    private var emptyVideosView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "video.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Recent Videos")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("No videos found in the last \(channel.lookbackDays) days")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: refreshVideos) {
                HStack {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isRefreshing ? "Refreshing..." : "Refresh Videos")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            .disabled(isRefreshing)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Videos List
    
    private var videosListView: some View {
        List {
            ForEach(videos) { video in
                ChannelVideoRowView(
                    video: video,
                    showChannelName: false, // Don't show channel name in detail view
                    onPlay: {
                        // Mark as watched and play video
                        channelsManager.markVideoAsWatched(videoID: video.id)
                        loadVideos() // Refresh to show updated watch status
                        
                        // Use the main video player callback if available
                        if let onVideoPlay = onVideoPlay {
                            onVideoPlay(video.id)
                            // Dismiss the detail view to show the main player
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            print("🎬 Playing video: \(video.title)")
                        }
                    },
                    onToggleWatched: {
                        // Toggle watch status
                        channelsManager.markVideoAsWatched(videoID: video.id)
                        loadVideos() // Refresh to show updated status
                    },
                    favoritesManager: favoritesManager
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            refreshVideos()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadVideos() {
        videos = channelsManager.getVideosForChannel(channel.id)
    }
    
    private func refreshVideos() {
        isRefreshing = true
        channelsManager.fetchChannelVideos(for: channel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadVideos()
            isRefreshing = false
        }
    }
}

// MARK: - Channel Video Row View

struct ChannelVideoRowView: View {
    let video: ChannelVideo
    let showChannelName: Bool
    let onPlay: () -> Void
    let onToggleWatched: () -> Void
    let onChannelTap: ((String) -> Void)?
    let favoritesManager: FavoritesManager?
    
    init(video: ChannelVideo, showChannelName: Bool = false, onPlay: @escaping () -> Void, onToggleWatched: @escaping () -> Void, onChannelTap: ((String) -> Void)? = nil, favoritesManager: FavoritesManager? = nil) {
        self.video = video
        self.showChannelName = showChannelName
        self.onPlay = onPlay
        self.onToggleWatched = onToggleWatched
        self.onChannelTap = onChannelTap
        self.favoritesManager = favoritesManager
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Video thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 68)
                .overlay(
                    VStack {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        if let duration = video.duration {
                            Text(duration)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.black.opacity(0.7))
                                )
                        }
                    }
                )
                .onTapGesture {
                    onPlay()
                }
            
            // Video info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(video.title)
                        .font(.headline)
                        .foregroundColor(video.isWatched ? .secondary : .primary)
                        .lineLimit(2)
                        .strikethrough(video.isWatched)
                    
                    Spacer()
                    
                    // Favorite indicator
                    if let favoritesManager = favoritesManager, favoritesManager.isFavorite(videoID: video.id) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                // Channel name (if showing)
                if showChannelName {
                    Button(action: {
                        onChannelTap?(video.channelID)
                    }) {
                        Text(video.channelName)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack {
                    if let viewCount = video.viewCount {
                        Text(viewCount)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(timeAgoString(from: video.publishedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if video.isWatched, let watchedAt = video.watchedAt {
                    Text("Watched \(timeAgoString(from: watchedAt))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Watch status toggle
            Button(action: onToggleWatched) {
                Image(systemName: video.isWatched ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(video.isWatched ? .green : .gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .opacity(video.isWatched ? 0.7 : 1.0)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Favorite/Unfavorite action
            if let favoritesManager = favoritesManager {
                Button {
                    if favoritesManager.isFavorite(videoID: video.id) {
                        favoritesManager.removeFavorite(videoID: video.id)
                    } else {
                        // Convert ChannelVideo to Video for favorites
                        let favoriteVideo = Video(
                            id: video.id,
                            title: video.title,
                            timestamp: Date() // Use current time for favorites ordering
                        )
                        favoritesManager.addFavorite(favoriteVideo)
                    }
                } label: {
                    Label(
                        favoritesManager.isFavorite(videoID: video.id) ? "Unfavorite" : "Favorite",
                        systemImage: favoritesManager.isFavorite(videoID: video.id) ? "star.slash" : "star"
                    )
                }
                .tint(favoritesManager.isFavorite(videoID: video.id) ? .orange : .yellow)
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Channel Settings View

struct ChannelSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    let channel: Channel
    let channelsManager: ChannelsManager
    
    @State private var lookbackDays: Double
    @State private var isActive: Bool
    @State private var showingDeleteAlert = false
    
    init(channel: Channel, channelsManager: ChannelsManager) {
        self.channel = channel
        self.channelsManager = channelsManager
        self._lookbackDays = State(initialValue: Double(channel.lookbackDays))
        self._isActive = State(initialValue: channel.isActive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Channel Settings")) {
                    HStack {
                        Text("Active")
                        Spacer()
                        Toggle("", isOn: $isActive)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Lookback Period")
                            Spacer()
                            Text("\(Int(lookbackDays)) days")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $lookbackDays, in: 1...30, step: 1)
                        
                        Text("How many days back to check for new videos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Channel Information")) {
                    if let handle = channel.handle {
                        HStack {
                            Text("Handle")
                            Spacer()
                            Text(handle)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Added")
                        Spacer()
                        Text(DateFormatter.localizedString(from: channel.dateAdded, dateStyle: .medium, timeStyle: .none))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(timeAgoString(from: channel.lastUpdated))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Text("Remove Channel")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Channel Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Remove Channel", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    channelsManager.removeChannel(channelID: channel.id)
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Are you sure you want to remove '\(channel.name)'? This will also remove all associated videos.")
            }
        }
    }
    
    private func saveSettings() {
        var updatedChannel = channel
        updatedChannel.lookbackDays = Int(lookbackDays)
        updatedChannel.isActive = isActive
        updatedChannel.lastUpdated = Date()
        
        channelsManager.updateChannel(updatedChannel)
        
        // If lookback period changed, refresh videos
        if Int(lookbackDays) != channel.lookbackDays {
            channelsManager.fetchChannelVideos(for: updatedChannel)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

struct ChannelDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockChannel = Channel(
            id: "UC123456789",
            name: "Sample Channel",
            handle: "@samplechannel",
            description: "A sample YouTube channel for preview"
        )
        
        ChannelDetailView(channel: mockChannel, channelsManager: ChannelsManager(), favoritesManager: FavoritesManager())
    }
}
