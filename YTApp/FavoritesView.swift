import SwiftUI

struct FavoritesView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    var onSelectVideo: (String) -> Void

    var body: some View {
        NavigationView {
            List {
                if favoritesManager.favorites.isEmpty {
                    VStack {
                        Image(systemName: "star")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No favorite videos")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Swipe left on videos in History to add favorites")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    // Random button section
                    Section {
                        Button(action: {
                            if let randomVideo = favoritesManager.favorites.randomElement() {
                                onSelectVideo(randomVideo.id)
                            }
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                    .foregroundColor(.white)
                                Text("Play Random Favorite")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.purple)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    
                    // Favorite videos section
                    Section("Favorite Videos") {
                        ForEach(favoritesManager.favorites) { video in
                            VideoRowView(video: video, isFavorite: true) {
                                onSelectVideo(video.id)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    if let index = favoritesManager.favorites.firstIndex(where: { $0.id == video.id }) {
                                        favoritesManager.removeFavorite(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Remove", systemImage: "star.slash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
