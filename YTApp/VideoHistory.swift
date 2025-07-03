import Foundation

class VideoHistory: ObservableObject, Identifiable {
    let id = UUID()
    var videoID: String?
    var title: String?
    var originalURL: String?
    var thumbnailURL: String?
    var watchDate: Date?
    
    init() {}
    
    init(videoID: String, title: String, originalURL: String, thumbnailURL: String, watchDate: Date) {
        self.videoID = videoID
        self.title = title
        self.originalURL = originalURL
        self.thumbnailURL = thumbnailURL
        self.watchDate = watchDate
    }
}
