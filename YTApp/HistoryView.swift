import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var favoritesManager: FavoritesManager
    let onVideoSelected: (String) -> Void
    
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
                    
                    // Video list
                    Section("Recent Videos") {
                        ForEach(historyManager.history) { video in
                            VideoRowView(
                                video: video,
                                isFavorite: favoritesManager.isFavorite(videoID: video.id),
                                onVideoTap: {
                                    onVideoSelected(video.id)
                                },
                                onFavoriteToggle: {
                                    if favoritesManager.isFavorite(videoID: video.id) {
                                        favoritesManager.removeFavorite(videoID: video.id)
                                    } else {
                                        favoritesManager.addFavorite(videoID: video.id)
                                    }
                                },
                                onDelete: {
                                    if let index = historyManager.history.firstIndex(where: { $0.id == video.id }) {
                                        historyManager.deleteVideo(at: IndexSet(integer: index))
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("History")
            .listStyle(PlainListStyle())
        }
    }
}

struct VideoRowView: View {
    let video: Video
    let isFavorite: Bool
    let onVideoTap: () -> Void
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    
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
            
            // Favorite button
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onVideoTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: onFavoriteToggle) {
                Label(
                    isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(.yellow)
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
