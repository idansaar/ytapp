import SwiftUI

struct ChannelsView: View {
    @ObservedObject var channelsManager: ChannelsManager
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var playbackPositionManager: PlaybackPositionManager
    let onVideoPlay: ((String) -> Void)?
    @State private var showingAddChannel = false
    @State private var selectedChannel: Channel?
    @State private var showingChannelDetail = false
    @State private var selectedChannelFilter: String? = nil // nil means show all
    @State private var showingChannelFilter = false
    @State private var isLoadingVideos = false
    
    init(channelsManager: ChannelsManager? = nil, favoritesManager: FavoritesManager? = nil, playbackPositionManager: PlaybackPositionManager? = nil, onVideoPlay: ((String) -> Void)? = nil) {
        if let manager = channelsManager {
            self.channelsManager = manager
        } else {
            self.channelsManager = ChannelsManager()
        }
        
        if let favManager = favoritesManager {
            self.favoritesManager = favManager
        } else {
            self.favoritesManager = FavoritesManager()
        }
        
        if let positionManager = playbackPositionManager {
            self.playbackPositionManager = positionManager
        } else {
            self.playbackPositionManager = PlaybackPositionManager()
        }
        
        self.onVideoPlay = onVideoPlay
    }
    
    // Computed property to get all videos from all channels
    private var allVideos: [ChannelVideo] {
        var videos: [ChannelVideo] = []
        for (_, channelVideos) in channelsManager.channelVideos {
            videos.append(contentsOf: channelVideos)
        }
        return videos.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    // Filtered videos based on selected channel
    private var filteredVideos: [ChannelVideo] {
        if let selectedChannelFilter = selectedChannelFilter {
            return allVideos.filter { $0.channelID == selectedChannelFilter }
        }
        return allVideos
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if channelsManager.channels.isEmpty {
                    // Empty state
                    emptyStateView
                } else if allVideos.isEmpty {
                    // No videos state
                    noVideosStateView
                } else {
                    // Videos list with filter
                    videosListView
                }
            }
            .navigationTitle("Channels")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Channel filter button
                    if !channelsManager.channels.isEmpty {
                        Button(action: {
                            showingChannelFilter = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                if let selectedChannelFilter = selectedChannelFilter,
                                   let channel = channelsManager.getChannelByID(selectedChannelFilter) {
                                    Text(channel.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                } else {
                                    Text("All")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Manage channels button
                        if !channelsManager.channels.isEmpty {
                            Button(action: {
                                showingChannelDetail = true
                                selectedChannel = nil // Show channel management
                            }) {
                                Image(systemName: "gear")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Refresh button
                        Button(action: {
                            channelsManager.refreshAllChannels()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .disabled(channelsManager.isLoading)
                        
                        // Add channel button
                        Button(action: {
                            showingAddChannel = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddChannel) {
                AddChannelView(channelsManager: channelsManager)
            }
            .sheet(isPresented: $showingChannelDetail) {
                if let channel = selectedChannel {
                    ChannelDetailView(
                        channel: channel, 
                        channelsManager: channelsManager, 
                        favoritesManager: favoritesManager, 
                        playbackPositionManager: playbackPositionManager,
                        onVideoPlay: onVideoPlay
                    )
                } else {
                    ChannelManagementView(channelsManager: channelsManager, favoritesManager: favoritesManager)
                }
            }
            .actionSheet(isPresented: $showingChannelFilter) {
                channelFilterActionSheet
            }
            .alert("Error", isPresented: .constant(channelsManager.errorMessage != nil)) {
                Button("OK") {
                    channelsManager.errorMessage = nil
                }
            } message: {
                Text(channelsManager.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "tv.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Channels Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Add YouTube channels to track their latest videos")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                showingAddChannel = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Channel")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - No Videos State View
    
    private var noVideosStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "video.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Recent Videos")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Your subscribed channels haven't posted any videos recently")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                channelsManager.refreshAllChannels()
            }) {
                HStack(spacing: 8) {
                    if channelsManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(channelsManager.isLoading ? "Refreshing..." : "Refresh Channels")
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
            .disabled(channelsManager.isLoading)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Videos List View
    
    private var videosListView: some View {
        VStack(spacing: 0) {
            // Summary header
            summaryHeaderView
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
            
            // Videos list
            List {
                ForEach(filteredVideos) { video in
                    ChannelVideoRowView(
                        video: video,
                        showChannelName: selectedChannelFilter == nil, // Show channel name when showing all videos
                        onPlay: {
                            // Mark as watched and play video
                            channelsManager.markVideoAsWatched(videoID: video.id)
                            
                            // Use the main video player callback
                            if let onVideoPlay = onVideoPlay {
                                onVideoPlay(video.id)
                            } else {
                                print("🎬 Playing video: \(video.title)")
                            }
                        },
                        onPlayFromBeginning: {
                            // Clear saved position and restart from beginning
                            playbackPositionManager.clearPosition(for: video.id)
                            channelsManager.markVideoAsWatched(videoID: video.id)
                            
                            // Use the regular play callback (position was cleared so it will start from beginning)
                            if let onVideoPlay = onVideoPlay {
                                onVideoPlay(video.id)
                            } else {
                                print("🔄 Restarting video: \(video.title)")
                            }
                        },
                        onToggleWatched: {
                            // Toggle watch status
                            channelsManager.markVideoAsWatched(videoID: video.id)
                        },
                        onChannelTap: selectedChannelFilter == nil ? { channelID in
                            // Show channel detail when tapping channel name
                            if let channel = channelsManager.getChannelByID(channelID) {
                                selectedChannel = channel
                                showingChannelDetail = true
                            }
                        } : nil,
                        favoritesManager: favoritesManager,
                        playbackPositionManager: playbackPositionManager
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                isLoadingVideos = true
                channelsManager.refreshAllChannels()
                // Simulate loading delay for better UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoadingVideos = false
                }
            }
        }
    }
    
    // MARK: - Channel Filter Action Sheet
    
    private var channelFilterActionSheet: ActionSheet {
        var buttons: [ActionSheet.Button] = []
        
        // "All Channels" option
        buttons.append(.default(Text("All Channels")) {
            selectedChannelFilter = nil
        })
        
        // Individual channel options
        for channel in channelsManager.channels {
            let unwatchedCount = channelsManager.getUnwatchedVideosCount(for: channel.id)
            let title = unwatchedCount > 0 ? "\(channel.name) (\(unwatchedCount) new)" : channel.name
            
            buttons.append(.default(Text(title)) {
                selectedChannelFilter = channel.id
            })
        }
        
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text("Filter by Channel"),
            message: Text("Choose which channel's videos to display"),
            buttons: buttons
        )
    }
    
    // MARK: - Summary Header
    
    private var summaryHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let selectedChannelFilter = selectedChannelFilter,
                   let channel = channelsManager.getChannelByID(selectedChannelFilter) {
                    Text(channel.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let channelVideos = filteredVideos.count
                    let unwatchedCount = filteredVideos.filter { !$0.isWatched }.count
                    Text("\(channelVideos) videos • \(unwatchedCount) unwatched")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(channelsManager.channels.count) Channels")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let totalVideos = allVideos.count
                    let unwatchedCount = channelsManager.getTotalUnwatchedCount()
                    Text("\(totalVideos) videos • \(unwatchedCount) unwatched")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if channelsManager.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Updating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Channel Row View

struct ChannelRowView: View {
    let channel: Channel
    let channelsManager: ChannelsManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Channel thumbnail placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "tv")
                            .foregroundColor(.gray)
                            .font(.title3)
                    )
                
                // Channel info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(channel.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if !channel.isActive {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    
                    if let handle = channel.handle {
                        Text(handle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Updated \(timeAgoString(from: channel.lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let unwatchedCount = channelsManager.getUnwatchedVideosCount(for: channel.id)
                        if unwatchedCount > 0 {
                            Text("\(unwatchedCount) new")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red)
                                )
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Add Channel View

struct AddChannelView: View {
    @Environment(\.presentationMode) var presentationMode
    let channelsManager: ChannelsManager
    
    @State private var channelInput = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add YouTube Channel")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enter a YouTube channel URL or search for a channel by name")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Channel URL or Name")
                            .font(.headline)
                        
                        TextField("", text: $channelInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Example formats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supported formats:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• https://youtube.com/@channelname")
                        Text("• https://youtube.com/c/ChannelName")
                        Text("• https://youtube.com/channel/UCxxxxx")
                        Text("• Channel Name (for search)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add button
                Button(action: addChannel) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isLoading ? "Adding Channel..." : "Add Channel")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(channelInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    )
                }
                .disabled(channelInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .navigationTitle("Add Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func addChannel() {
        let input = channelInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let foundChannels = try await channelsManager.searchChannels(query: input)
                
                await MainActor.run {
                    if let channel = foundChannels.first {
                        channelsManager.addChannel(channel)
                        isLoading = false
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        errorMessage = "No channels found for '\(input)'"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error searching for channel: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview

struct ChannelsView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsView()
    }
}
