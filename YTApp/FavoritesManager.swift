import Foundation

class FavoritesManager: ObservableObject {
    @Published var favorites: [Video] = []
    private let favoritesKey = "videoFavorites"

    init() {
        loadFavorites()
    }

    func addFavorite(_ video: Video) {
        if !favorites.contains(where: { $0.id == video.id }) {
            // Create a new video with current timestamp for favorites ordering
            let favoriteVideo = Video(
                id: video.id,
                title: video.title,
                timestamp: Date() // Use current time for favorites ordering
            )
            favorites.insert(favoriteVideo, at: 0)
            saveFavorites()
        }
    }
    
    func addFavorite(videoID: String) {
        // Try to find the video in history first to preserve metadata
        if let historyVideo = getVideoFromHistory(videoID: videoID) {
            addFavorite(historyVideo)
        } else {
            // Create a basic Video object for the favorite
            let video = Video(id: videoID, title: "YouTube Video", timestamp: Date())
            addFavorite(video)
        }
    }
    
    // Helper method to get video from history (if available)
    private func getVideoFromHistory(videoID: String) -> Video? {
        // This would ideally get the video from HistoryManager
        // For now, we'll create a new video with current timestamp
        return nil
    }

    func removeFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        saveFavorites()
    }
    
    func removeFavorite(videoID: String) {
        favorites.removeAll { $0.id == videoID }
        saveFavorites()
    }
    
    func clearAllFavorites() {
        favorites.removeAll()
        saveFavorites()
        print("⭐ All favorites cleared")
    }

    func isFavorite(_ video: Video) -> Bool {
        favorites.contains(where: { $0.id == video.id })
    }
    
    func isFavorite(videoID: String) -> Bool {
        favorites.contains(where: { $0.id == videoID })
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey), let decoded = try? JSONDecoder().decode([Video].self, from: data) {
            favorites = decoded
        }
    }
}
