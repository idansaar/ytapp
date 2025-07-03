import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @State private var selectedTab = 0
    @State private var currentVideoID: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Top section with video player and paste button
            VStack(spacing: 16) {
                // Paste & Play button at the top
                Button(action: {
                    print("🔘 Button tapped!")
                    print("📋 ClipboardManager URL: \(clipboardManager.url?.absoluteString ?? "nil")")
                    
                    if let url = clipboardManager.url {
                        print("✅ Using ClipboardManager URL")
                        currentVideoID = extractVideoID(from: url)
                    } else {
                        print("⚠️ ClipboardManager URL is nil, checking clipboard directly")
                        checkClipboardAndPlay()
                    }
                    
                    print("🎥 Current Video ID: \(currentVideoID ?? "nil")")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: clipboardManager.url != nil ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                        Text("Paste & Play")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(clipboardManager.url != nil ? Color.blue : Color.gray)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
                // Video player window
                if let videoID = currentVideoID {
                    VideoPlayerView(videoID: videoID)
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxHeight: 220)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .onAppear { historyManager.addVideo(id: videoID) }
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
            
            // Tab view for History and Favorites
            TabView(selection: $selectedTab) {
                HistoryView(historyManager: historyManager, favoritesManager: favoritesManager) { videoID in
                    currentVideoID = videoID
                }
                .tabItem { 
                    Image(systemName: "clock")
                    Text("History") 
                }.tag(0)
                
                FavoritesView(favoritesManager: favoritesManager) { videoID in
                    currentVideoID = videoID
                }
                .tabItem { 
                    Image(systemName: "star")
                    Text("Favorites") 
                }.tag(1)
            }
        }
        .onReceive(clipboardManager.$url) { url in
            if let url = url {
                currentVideoID = extractVideoID(from: url)
            }
        }
    }
    
    private func checkClipboardAndPlay() {
        print("🔍 Checking clipboard directly...")
        if let clipboardString = UIPasteboard.general.string {
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
                    currentVideoID = videoID
                    return
                }
            }
            print("❌ No YouTube URL found in clipboard")
        } else {
            print("❌ Clipboard is empty")
        }
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
