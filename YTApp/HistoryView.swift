import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var persistenceController: PersistenceController
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingVideoPlayer = false
    @State private var selectedVideoURL: URL?
    @StateObject private var youtubeService = YouTubeService()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(persistenceController.videos) { video in
                    VideoHistoryRow(video: video) {
                        playVideo(video)
                    }
                }
                .onDelete(perform: deleteVideos)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let videoURL = selectedVideoURL {
                VideoPlayerView(videoURL: videoURL, isPresented: $showingVideoPlayer)
            }
        }
    }
    
    private func playVideo(_ video: VideoHistory) {
        guard let originalURL = video.originalURL,
              let videoURL = youtubeService.extractVideoURL(from: originalURL) else {
            return
        }
        
        selectedVideoURL = videoURL
        showingVideoPlayer = true
        
        video.watchDate = Date()
        persistenceController.saveVideo(video)
    }
    
    private func deleteVideos(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let video = persistenceController.videos[index]
                persistenceController.deleteVideo(video)
            }
        }
    }
}

struct VideoHistoryRow: View {
    let video: VideoHistory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "play.rectangle")
                            .foregroundColor(.gray)
                            .font(.title2)
                    )
                    .frame(width: 120, height: 68)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title ?? "Unknown Video")
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let watchDate = video.watchDate {
                        Text(formatDate(watchDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
