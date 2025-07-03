import Foundation

class FavoritesManager: ObservableObject {
    @Published var favorites: [Video] = []
    private let favoritesKey = "videoFavorites"

    init() {
        loadFavorites()
    }

    func addFavorite(_ video: Video) {
        if !favorites.contains(where: { $0.id == video.id }) {
            favorites.insert(video, at: 0)
            saveFavorites()
        }
    }

    func removeFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        saveFavorites()
    }

    func isFavorite(_ video: Video) -> Bool {
        favorites.contains(where: { $0.id == video.id })
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
