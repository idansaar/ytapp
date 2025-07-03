import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    @Published var videos: [VideoHistory] = []
    
    static var preview: PersistenceController = {
        let result = PersistenceController()
        
        let sampleVideo = VideoHistory(
            videoID: "dQw4w9WgXcQ",
            title: "Rick Astley - Never Gonna Give You Up",
            originalURL: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            thumbnailURL: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            watchDate: Date()
        )
        
        result.videos.append(sampleVideo)
        return result
    }()
    
    init() {}
    
    func saveVideo(_ video: VideoHistory) {
        if let existingIndex = videos.firstIndex(where: { $0.videoID == video.videoID }) {
            videos[existingIndex].watchDate = Date()
            let existingVideo = videos.remove(at: existingIndex)
            videos.insert(existingVideo, at: 0)
        } else {
            videos.insert(video, at: 0)
        }
    }
    
    func deleteVideo(_ video: VideoHistory) {
        videos.removeAll { $0.id == video.id }
    }
}
