import Foundation
import Combine
import UIKit

class ClipboardManager: ObservableObject {
    @Published var url: URL?
    private var pasteboard = UIPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int = 0

    init() {
        // Check current clipboard content on initialization
        checkClipboard()
        
        // Set up timer-based monitoring to avoid permission prompts
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        
        // Only check if clipboard content has changed
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let clipboardString = pasteboard.string {
                let extractedURL = extractYouTubeURL(from: clipboardString)
                
                DispatchQueue.main.async {
                    self.url = extractedURL
                }
            } else {
                DispatchQueue.main.async {
                    self.url = nil
                }
            }
        }
    }

    private func extractYouTubeURL(from string: String) -> URL? {
        let patterns = [
            "(?:https?://)?(?:www\\.)?youtube\\.com/watch\\?v=([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtu\\.be/([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtube\\.com/embed/([a-zA-Z0-9_\\-]+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) {
                let videoID = String(string[Range(match.range(at: 1), in: string)!])
                return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
            }
        }
        return nil
    }
    
    deinit {
        timer?.invalidate()
    }
}
