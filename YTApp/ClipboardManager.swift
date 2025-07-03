import Foundation
import Combine
import UIKit

class ClipboardManager: ObservableObject {
    @Published var url: URL?
    private var pasteboard = UIPasteboard.general
    private var cancellable: AnyCancellable?

    init() {
        // Check current clipboard content on initialization
        if let currentString = pasteboard.string {
            url = extractYouTubeURL(from: currentString)
        }
        
        // Set up listener for clipboard changes
        cancellable = NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
            .compactMap { _ in self.pasteboard.string }
            .compactMap { self.extractYouTubeURL(from: $0) }
            .removeDuplicates()
            .assign(to: \.url, on: self)
    }

    private func extractYouTubeURL(from string: String) -> URL? {
        let patterns = [
            "(?:https?://)?(?:www\\.)?youtube\\.com/watch\\?v=([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtu\\.be/([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtube\\.com/embed/([a-zA-Z0-9_\\-]+)"
        ]

        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern)
            if let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) {
                let videoID = String(string[Range(match.range(at: 1), in: string)!])
                return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
            }
        }
        return nil
    }
}
