import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var favoritesManager: FavoritesManager
    var onSelectVideo: (String) -> Void

    var body: some View {
        NavigationView {
            List {
                if historyManager.history.isEmpty {
                    VStack {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No recently played videos")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Videos you play will appear here")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    // Random button section
                    Section {
                        Button(action: {
                            if let randomVideo = historyManager.history.randomElement() {
                                onSelectVideo(randomVideo.id)
                            }
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                    .foregroundColor(.white)
                                Text("Play Random Video")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    
                    // History videos section
                    Section("Recent Videos") {
                        ForEach(historyManager.history) { video in
                            VideoRowView(video: video, isFavorite: favoritesManager.isFavorite(video)) {
                                onSelectVideo(video.id)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    if let index = historyManager.history.firstIndex(where: { $0.id == video.id }) {
                                        historyManager.deleteVideo(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if !favoritesManager.isFavorite(video) {
                                    Button {
                                        favoritesManager.addFavorite(video)
                                    } label: {
                                        Label("Favorite", systemImage: "star")
                                    }
                                    .tint(.yellow)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct VideoRowView: View {
    let video: Video
    let isFavorite: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(video.id)/0.jpg")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 120, height: 90)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(video.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
