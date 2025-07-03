import SwiftUI

struct ChannelsView: View {
    @ObservedObject var channelsManager: ChannelsManager
    let onVideoPlay: ((String) -> Void)?
    @State private var showingAddChannel = false
    @State private var selectedChannel: Channel?
    @State private var showingChannelDetail = false
    
    init(channelsManager: ChannelsManager? = nil, onVideoPlay: ((String) -> Void)? = nil) {
        if let manager = channelsManager {
            self.channelsManager = manager
        } else {
            self.channelsManager = ChannelsManager()
        }
        self.onVideoPlay = onVideoPlay
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if channelsManager.channels.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Channels list
                    channelsListView
                }
            }
            .navigationTitle("Channels")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
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
                    ChannelDetailView(channel: channel, channelsManager: channelsManager, onVideoPlay: onVideoPlay)
                }
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
    
    // MARK: - Channels List View
    
    private var channelsListView: some View {
        VStack(spacing: 0) {
            // Summary header
            if !channelsManager.channels.isEmpty {
                summaryHeaderView
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
            }
            
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
                        
                        TextField("https://youtube.com/@channelname or Channel Name", text: $channelInput)
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
        
        // TODO: Implement actual channel parsing and API integration
        // For now, create a mock channel
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockChannel = Channel(
                id: "UC\(UUID().uuidString.prefix(10))",
                name: input.hasPrefix("http") ? "Channel from URL" : input,
                handle: "@\(input.lowercased().replacingOccurrences(of: " ", with: ""))",
                description: "A YouTube channel added via \(input.hasPrefix("http") ? "URL" : "search")"
            )
            
            channelsManager.addChannel(mockChannel)
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

struct ChannelsView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsView()
    }
}
