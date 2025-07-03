import Foundation

struct Video: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var timestamp: Date
}

class HistoryManager: ObservableObject {
    @Published var history: [Video] = []
    private let historyKey = "videoHistory"

    init() {
        loadHistory()
    }

    func addVideo(id: String) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            let video = history.remove(at: index)
            history.insert(video, at: 0)
        } else {
            let newVideo = Video(id: id, title: "Loading...", timestamp: Date())
            history.insert(newVideo, at: 0)
            fetchVideoTitle(id: id)
        }
        saveHistory()
    }

    func deleteVideo(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    private func fetchVideoTitle(id: String) {
        guard let url = URL(string: "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(id)&format=json") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let oembed = try? JSONDecoder().decode(Oembed.self, from: data) else { return }
            DispatchQueue.main.async {
                if let index = self.history.firstIndex(where: { $0.id == id }) {
                    self.history[index].title = oembed.title
                    self.saveHistory()
                }
            }
        }.resume()
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey), let decoded = try? JSONDecoder().decode([Video].self, from: data) {
            history = decoded
            history.forEach { video in
                if video.title == "Loading..." {
                    fetchVideoTitle(id: video.id)
                }
            }
        }
    }
}

struct Oembed: Codable {
    var title: String
}
