import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @State private var selectedTab = 0
    @State private var currentVideoID: String? = nil
    @State private var hasAddedToHistory = false // Track if we've already added to history
    @State private var useAVPlayer = false // Toggle between WebKit and AVKit players
    @State private var showPlayerSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Top section with video player and paste button
            VStack(spacing: 16) {
                // Player controls and settings
                HStack {
                    // Paste & Play button
                    Button(action: {
                        playFromClipboard()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: clipboardManager.url != nil ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                            Text("Paste & Play")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(clipboardManager.url != nil ? Color.blue : Color.gray)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Player type toggle
                    Button(action: {
                        showPlayerSettings.toggle()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                // Video player window
                if let videoID = currentVideoID {
                    Group {
                        if useAVPlayer {
                            // AVKit player with PiP support
                            AVVideoPlayerView(videoID: videoID) {
                                // History already added in setCurrentVideo, just log playback start
                                print("▶️ AVPlayer playback started for: \(videoID)")
                            }
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxHeight: 220)
                            .cornerRadius(12)
                            .overlay(
                                // Demo mode indicator
                                VStack {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 2) {
                                            Text("DEMO")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                            Text("PiP Mode")
                                                .font(.caption2)
                                        }
                                        .padding(6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                    }
                                    Spacer()
                                }
                                .padding(8)
                            )
                        } else {
                            // WebKit player (original)
                            VideoPlayerView(videoID: videoID) {
                                // History already added in setCurrentVideo, just log playback start
                                print("▶️ WebKit playback started for: \(videoID)")
                            }
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxHeight: 220)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .id(videoID) // Use ID to prevent unnecessary updates
                } else {
                    // Placeholder when no video is selected
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxHeight: 220)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "play.rectangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Copy a YouTube link and tap 'Paste & Play'")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        )
                        .padding(.horizontal)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            .background(Color(.systemBackground))
            
            // Tab view for History, Channels, and Favorites
            TabView(selection: $selectedTab) {
                HistoryView(historyManager: historyManager, favoritesManager: favoritesManager) { videoID in
                    print("🎯 Playing video from history: \(videoID)")
                    setCurrentVideo(videoID)
                }
                .tabItem { 
                    Image(systemName: "clock")
                    Text("History") 
                }.tag(0)
                
                ChannelsView()
                .tabItem { 
                    Image(systemName: "tv")
                    Text("Channels") 
                }.tag(1)
                
                FavoritesView(favoritesManager: favoritesManager) { videoID in
                    print("⭐ Playing video from favorites: \(videoID)")
                    setCurrentVideo(videoID)
                }
                .tabItem { 
                    Image(systemName: "star")
                    Text("Favorites") 
                }.tag(2)
            }
        }
        .onReceive(clipboardManager.$url) { url in
            if let url = url {
                let videoID = extractVideoID(from: url)
                print("📋 New URL detected: \(url.absoluteString)")
                print("🎥 Extracted video ID: \(videoID ?? "nil")")
                
                if let videoID = videoID {
                    // Auto-play the new video (history will be added when playback starts)
                    setCurrentVideo(videoID)
                }
            }
        }
        .onAppear {
            // Configure background playback on app launch
            AVVideoPlayerView.configureBackgroundPlayback()
        }
        .sheet(isPresented: $showPlayerSettings) {
            PlayerSettingsView(useAVPlayer: $useAVPlayer)
        }
    }
    
    private func setCurrentVideo(_ videoID: String) {
        // Only update if it's actually a different video
        if currentVideoID != videoID {
            currentVideoID = videoID
            hasAddedToHistory = false // Reset history flag for new video
            
            // Add to history immediately (like favorites promotion)
            historyManager.addVideo(id: videoID)
            hasAddedToHistory = true
            
            // Try to get video title from history for better metadata
            let videoTitle = historyManager.history.first(where: { $0.id == videoID })?.title ?? "YouTube Video"
            
            // Promote video to top of favorites if it exists there
            favoritesManager.promoteVideoToTop(videoID: videoID, title: videoTitle)
            
            print("🎬 Set current video to: \(videoID)")
        }
    }
    
    private func playFromClipboard() {
        print("🔘 Paste & Play button tapped!")
        
        if let url = clipboardManager.url {
            print("✅ Using ClipboardManager URL: \(url.absoluteString)")
            if let videoID = extractVideoID(from: url) {
                setCurrentVideo(videoID)
                print("🎬 Playing video: \(videoID)")
            }
        } else {
            print("⚠️ No URL available from ClipboardManager")
            checkClipboardDirectly()
        }
    }
    
    private func checkClipboardDirectly() {
        print("🔍 Checking clipboard directly...")
        
        // Use a safer approach to check clipboard
        guard UIPasteboard.general.hasStrings else {
            print("❌ No string content in clipboard")
            return
        }
        
        guard let clipboardString = UIPasteboard.general.string else {
            print("❌ Could not access clipboard string")
            return
        }
        
        print("📝 Clipboard content: \(clipboardString)")
        let patterns = [
            "(?:https?://)?(?:www\\.)?youtube\\.com/watch\\?v=([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtu\\.be/([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtube\\.com/embed/([a-zA-Z0-9_\\-]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: clipboardString, range: NSRange(clipboardString.startIndex..., in: clipboardString)) {
                let videoID = String(clipboardString[Range(match.range(at: 1), in: clipboardString)!])
                print("✅ Found video ID: \(videoID)")
                setCurrentVideo(videoID)
                return
            }
        }
        print("❌ No YouTube URL found in clipboard")
    }

    private func extractVideoID(from url: URL) -> String? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItem = components.queryItems?.first(where: { $0.name == "v" }) {
            return queryItem.value
        }
        let path = url.path
        if path.starts(with: "/embed/") {
            return String(path.dropFirst("/embed/".count))
        }
        if !url.pathExtension.isEmpty {
            return url.lastPathComponent
        }
        return url.lastPathComponent
    }
}
