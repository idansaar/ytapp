import Foundation

class YouTubeService: ObservableObject {
    private let persistenceController = PersistenceController.shared
    
    func extractVideoURL(from urlString: String) -> URL? {
        guard let videoID = extractVideoID(from: urlString) else {
            return nil
        }
        return URL(string: "https://www.youtube.com/embed/\(videoID)")
    }
    
    func extractVideoID(from urlString: String) -> String? {
        let patterns = [
            "(?:youtube\\.com/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com/embed/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com/v/)([a-zA-Z0-9_-]{11})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: urlString.count)
                if let match = regex.firstMatch(in: urlString, options: [], range: range) {
                    let videoIDRange = match.range(at: 1)
                    if let swiftRange = Range(videoIDRange, in: urlString) {
                        return String(urlString[swiftRange])
                    }
                }
            }
        }
        return nil
    }
    
    func saveToHistory(urlString: String) {
        let videoID = extractVideoID(from: urlString) ?? urlString
        
        let newVideo = VideoHistory(
            videoID: videoID,
            title: "YouTube Video \(videoID.prefix(8))",
            originalURL: urlString,
            thumbnailURL: "https://img.youtube.com/vi/\(videoID)/maxresdefault.jpg",
            watchDate: Date()
        )
        
        persistenceController.saveVideo(newVideo)
    }
}
