import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    @StateObject private var youtubeService = YouTubeService()
    @State private var showingVideoPlayer = false
    @State private var currentVideoURL: URL?
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("YTApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 15) {
                    Text("Paste & Play")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if clipboardMonitor.hasYouTubeURL {
                        Button(action: {
                            playFromClipboard()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Play from Clipboard")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                        
                        if let urlString = clipboardMonitor.detectedURL {
                            Text("Detected: \(urlString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("Copy a YouTube URL to clipboard")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    showingHistory = true
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View History")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let videoURL = currentVideoURL {
                VideoPlayerView(videoURL: videoURL, isPresented: $showingVideoPlayer)
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .onAppear {
            clipboardMonitor.startMonitoring()
        }
        .onDisappear {
            clipboardMonitor.stopMonitoring()
        }
    }
    
    private func playFromClipboard() {
        guard let urlString = clipboardMonitor.detectedURL,
              let videoURL = youtubeService.extractVideoURL(from: urlString) else {
            return
        }
        
        currentVideoURL = videoURL
        showingVideoPlayer = true
        youtubeService.saveToHistory(urlString: urlString)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PersistenceController.preview)
    }
}
