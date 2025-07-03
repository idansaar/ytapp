import Foundation

struct Video: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var timestamp: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class HistoryManager: ObservableObject {
    @Published var history: [Video] = []
    private let historyKey = "videoHistory"

    init() {
        loadHistory()
    }

    func addVideo(id: String) {
        print("🎥 Adding video to history: \(id)")
        
        // First, remove any existing video with the same ID
        if let existingIndex = history.firstIndex(where: { $0.id == id }) {
            print("📝 Found existing video at index \(existingIndex), removing it")
            history.remove(at: existingIndex)
        }
        
        // Create new video and add to the beginning
        let newVideo = Video(id: id, title: "Loading...", timestamp: Date())
        history.insert(newVideo, at: 0)
        print("✅ Video added to history. Total videos: \(history.count)")
        
        // Save immediately
        saveHistory()
        
        // Fetch title asynchronously
        fetchVideoTitle(id: id)
    }

    func deleteVideo(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func clearAllHistory() {
        history.removeAll()
        saveHistory()
        print("🗑️ All history cleared")
    }

    private func fetchVideoTitle(id: String) {
        guard let url = URL(string: "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(id)&format=json") else { 
            print("❌ Invalid URL for video ID: \(id)")
            return 
        }

        print("🌐 Fetching title for video: \(id)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching title: \(error)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received for video title")
                return
            }
            
            do {
                let oembed = try JSONDecoder().decode(Oembed.self, from: data)
                print("✅ Title fetched: \(oembed.title)")
                
                DispatchQueue.main.async {
                    if let index = self.history.firstIndex(where: { $0.id == id }) {
                        self.history[index].title = oembed.title
                        self.saveHistory()
                        print("📝 Title updated in history")
                    }
                }
            } catch {
                print("❌ Error decoding title: \(error)")
            }
        }.resume()
    }

    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(history)
            UserDefaults.standard.set(encoded, forKey: historyKey)
            print("💾 History saved with \(history.count) videos")
        } catch {
            print("❌ Error saving history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            print("📂 No existing history found")
            return
        }
        
        do {
            history = try JSONDecoder().decode([Video].self, from: data)
            print("📂 History loaded with \(history.count) videos")
            
            // Re-fetch titles for any videos that are still loading
            history.forEach { video in
                if video.title == "Loading..." {
                    fetchVideoTitle(id: video.id)
                }
            }
        } catch {
            print("❌ Error loading history: \(error)")
        }
    }
}

struct Oembed: Codable {
    var title: String
}
