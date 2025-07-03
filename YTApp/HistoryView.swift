import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var favoritesManager: FavoritesManager
    let onVideoSelected: (String) -> Void
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            List {
                if historyManager.history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No History Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Videos you watch will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    // Random video button
                    Section {
                        Button(action: {
                            if let randomVideo = historyManager.history.randomElement() {
                                onVideoSelected(randomVideo.id)
                            }
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                    .foregroundColor(.blue)
                                Text("Play Random Video")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("\(historyManager.history.count) videos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Video list with native swipe actions
                    Section("Recent Videos") {
                        ForEach(historyManager.history) { video in
                            VideoRowView(
                                video: video,
                                isFavorite: favoritesManager.isFavorite(videoID: video.id),
                                onVideoTap: {
                                    onVideoSelected(video.id)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Delete action
                                Button(role: .destructive) {
                                    if let index = historyManager.history.firstIndex(where: { $0.id == video.id }) {
                                        historyManager.deleteVideo(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                // Favorite action
                                Button {
                                    if favoritesManager.isFavorite(videoID: video.id) {
                                        favoritesManager.removeFavorite(videoID: video.id)
                                    } else {
                                        favoritesManager.addFavorite(videoID: video.id)
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
                }
            }
            .navigationTitle("History")
            .listStyle(PlainListStyle())
            .toolbar {
                if !historyManager.history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            showingClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear All History", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    historyManager.clearAllHistory()
                }
            } message: {
                Text("This will permanently delete all \(historyManager.history.count) videos from your history. This action cannot be undone.")
            }
        }
    }
}

struct VideoRowView: View {
    let video: Video
    let isFavorite: Bool
    let onVideoTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncThumbnailImage(videoID: video.id, quality: .medium)
                .frame(width: 120, height: 68)
                .cornerRadius(8)
                .clipped()
            
            // Video info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formatTimestamp(video.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("ID: \(video.id)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
            
            Spacer()
            
            // Favorite indicator (read-only)
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onVideoTap()
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HistoryView(
        historyManager: HistoryManager(),
        favoritesManager: FavoritesManager(),
        onVideoSelected: { _ in }
    )
}
