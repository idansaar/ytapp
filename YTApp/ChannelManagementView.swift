import SwiftUI

struct ChannelManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var channelsManager: ChannelsManager
    @ObservedObject var favoritesManager: FavoritesManager
    @State private var selectedChannel: Channel?
    @State private var showingChannelDetail = false
    
    init(channelsManager: ChannelsManager, favoritesManager: FavoritesManager) {
        self.channelsManager = channelsManager
        self.favoritesManager = favoritesManager
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if channelsManager.channels.isEmpty {
                    emptyStateView
                } else {
                    channelsListView
                }
            }
            .navigationTitle("Manage Channels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        channelsManager.refreshAllChannels()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(channelsManager.isLoading)
                }
            }
            .sheet(isPresented: $showingChannelDetail) {
                if let channel = selectedChannel {
                    ChannelDetailView(
                        channel: channel, 
                        channelsManager: channelsManager, 
                        favoritesManager: favoritesManager,
                        playbackPositionManager: PlaybackPositionManager() // Create a temporary instance
                    )
                }
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
                Text("No Channels")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Add channels from the main Channels tab to manage them here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Channels List View
    
    private var channelsListView: some View {
        VStack(spacing: 0) {
            // Summary header
            summaryHeaderView
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
            
            // Channels list
            List {
                ForEach(channelsManager.channels) { channel in
                    ChannelRowView(
                        channel: channel,
                        channelsManager: channelsManager,
                        onTap: {
                            selectedChannel = channel
                            showingChannelDetail = true
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: channelsManager.removeChannel)
            }
            .listStyle(PlainListStyle())
            .refreshable {
                channelsManager.refreshAllChannels()
            }
        }
    }
    
    // MARK: - Summary Header
    
    private var summaryHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(channelsManager.channels.count) Channels")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let unwatchedCount = channelsManager.getTotalUnwatchedCount()
                Text("\(unwatchedCount) unwatched videos")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// MARK: - Preview

struct ChannelManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelManagementView(channelsManager: ChannelsManager(), favoritesManager: FavoritesManager())
    }
}
