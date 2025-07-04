import SwiftUI

struct SettingsView: View {
    @ObservedObject var playbackPositionManager: PlaybackPositionManager
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var channelsManager: ChannelsManager
    @ObservedObject var errorManager: ErrorManager
    
    @State private var showingClearDataAlert = false
    @State private var showingAbout = false
    @State private var showingErrorHistory = false
    @State private var autoPlayFromClipboard = true
    @State private var savePlaybackPosition = true
    @State private var backgroundPlayback = true
    @State private var showChannelThumbnails = true
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Playback Settings
                Section(header: Text("Playback")) {
                    Toggle("Auto-play from Clipboard", isOn: $autoPlayFromClipboard)
                        .onChange(of: autoPlayFromClipboard) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "autoPlayFromClipboard")
                        }
                    
                    Toggle("Save Playback Position", isOn: $savePlaybackPosition)
                        .onChange(of: savePlaybackPosition) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "savePlaybackPosition")
                        }
                    
                    Toggle("Background Playback", isOn: $backgroundPlayback)
                        .onChange(of: backgroundPlayback) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "backgroundPlayback")
                        }
                }
                
                // MARK: - Interface Settings
                Section(header: Text("Interface")) {
                    Toggle("Show Channel Thumbnails", isOn: $showChannelThumbnails)
                        .onChange(of: showChannelThumbnails) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "showChannelThumbnails")
                        }
                }
                
                // MARK: - Data Management
                Section(header: Text("Data Management")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("History Items")
                                .font(.body)
                            Text("\(historyManager.history.count) videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            historyManager.clearAllHistory()
                        }
                        .foregroundColor(.red)
                        .disabled(historyManager.history.isEmpty)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Favorite Videos")
                                .font(.body)
                            Text("\(favoritesManager.favorites.count) videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            favoritesManager.clearAllFavorites()
                        }
                        .foregroundColor(.red)
                        .disabled(favoritesManager.favorites.isEmpty)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Channel Subscriptions")
                                .font(.body)
                            Text("\(channelsManager.channels.count) channels")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            channelsManager.clearAllChannels()
                        }
                        .foregroundColor(.red)
                        .disabled(channelsManager.channels.isEmpty)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Playback Positions")
                                .font(.body)
                            Text("\(playbackPositionManager.getAllPositions().count) saved positions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            playbackPositionManager.clearAllPositions()
                        }
                        .foregroundColor(.red)
                        .disabled(playbackPositionManager.getAllPositions().isEmpty)
                    }
                    
                    Button("Clear All Data") {
                        showingClearDataAlert = true
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // MARK: - Storage Info
                Section(header: Text("Storage")) {
                    HStack {
                        Text("Data Storage")
                        Spacer()
                        Text("UserDefaults")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cache Location")
                        Spacer()
                        Text("Local Device")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - About
                Section(header: Text("About")) {
                    Button("Error History") {
                        showingErrorHistory = true
                    }
                    
                    HStack {
                        Text("Recent Errors")
                        Spacer()
                        Text("\(errorManager.errorHistory.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("About YTApp") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("Production")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your history, favorites, channels, and playback positions. This action cannot be undone.")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingErrorHistory) {
                ErrorHistoryView(errorManager: errorManager)
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        autoPlayFromClipboard = UserDefaults.standard.bool(forKey: "autoPlayFromClipboard")
        savePlaybackPosition = UserDefaults.standard.bool(forKey: "savePlaybackPosition")
        backgroundPlayback = UserDefaults.standard.bool(forKey: "backgroundPlayback")
        showChannelThumbnails = UserDefaults.standard.bool(forKey: "showChannelThumbnails")
        
        // Set defaults if first time
        if UserDefaults.standard.object(forKey: "autoPlayFromClipboard") == nil {
            autoPlayFromClipboard = true
            UserDefaults.standard.set(true, forKey: "autoPlayFromClipboard")
        }
        if UserDefaults.standard.object(forKey: "savePlaybackPosition") == nil {
            savePlaybackPosition = true
            UserDefaults.standard.set(true, forKey: "savePlaybackPosition")
        }
        if UserDefaults.standard.object(forKey: "backgroundPlayback") == nil {
            backgroundPlayback = true
            UserDefaults.standard.set(true, forKey: "backgroundPlayback")
        }
        if UserDefaults.standard.object(forKey: "showChannelThumbnails") == nil {
            showChannelThumbnails = true
            UserDefaults.standard.set(true, forKey: "showChannelThumbnails")
        }
    }
    
    private func clearAllData() {
        historyManager.clearAllHistory()
        favoritesManager.clearAllFavorites()
        channelsManager.clearAllChannels()
        playbackPositionManager.clearAllPositions()
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("YTApp")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Streamlined YouTube Video Player")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        FeatureRow(icon: "clipboard", title: "Paste & Play", description: "Instant YouTube video playback from clipboard")
                        FeatureRow(icon: "clock.arrow.circlepath", title: "Resume Playback", description: "Automatically resume videos from where you left off")
                        FeatureRow(icon: "heart", title: "Favorites", description: "Save and organize your favorite videos")
                        FeatureRow(icon: "tv", title: "Channel Management", description: "Subscribe to channels and track new videos")
                        FeatureRow(icon: "speaker.wave.2", title: "Background Audio", description: "Continue listening when app is backgrounded")
                    }
                    
                    // Technical Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Technical Details")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        InfoRow(title: "Platform", value: "iOS 14.0+")
                        InfoRow(title: "Framework", value: "SwiftUI + WebKit")
                        InfoRow(title: "Video Player", value: "WebKit (YouTube Compatible)")
                        InfoRow(title: "Data Storage", value: "UserDefaults (Local)")
                        InfoRow(title: "Architecture", value: "MVVM Pattern")
                    }
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Notice")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This app is designed for personal use and educational purposes. It respects YouTube's terms of service by using their embedded player. No videos are downloaded or stored locally.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView(
        playbackPositionManager: PlaybackPositionManager(),
        historyManager: HistoryManager(),
        favoritesManager: FavoritesManager(),
        channelsManager: ChannelsManager(),
        errorManager: ErrorManager()
    )
}
