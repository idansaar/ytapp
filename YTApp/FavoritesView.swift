import SwiftUI

struct FavoritesView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    let onVideoSelected: (String) -> Void
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            List {
                if favoritesManager.favorites.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Favorites Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Tap the star icon on videos to add them to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section("Favorite Videos") {
                        ForEach(favoritesManager.favorites) { video in
                            FavoriteVideoRowView(
                                video: video,
                                onVideoTap: {
                                    onVideoSelected(video.id)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    favoritesManager.removeFavorite(videoID: video.id)
                                } label: {
                                    Label("Remove", systemImage: "star.slash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .listStyle(PlainListStyle())
            .toolbar {
                if !favoritesManager.favorites.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            showingClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear All Favorites", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    favoritesManager.clearAllFavorites()
                }
            } message: {
                Text("This will permanently remove all \(favoritesManager.favorites.count) videos from your favorites. This action cannot be undone.")
            }
        }
    }
}

struct FavoriteVideoRowView: View {
    let video: Video
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
                
                Text(formatTimestamp(video.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("ID: \(video.id)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
            
            Spacer()
            
            // Favorite indicator
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title3)
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
    FavoritesView(
        favoritesManager: FavoritesManager(),
        onVideoSelected: { _ in }
    )
}
