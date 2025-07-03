import Foundation
import Combine
import UIKit

class ClipboardManager: ObservableObject {
    @Published var url: URL?
    private var pasteboard = UIPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastKnownURL: String?

    init() {
        // Check current clipboard content on initialization
        checkClipboard()
        
        // Set up timer-based monitoring to avoid permission prompts
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        // Safely access pasteboard with error handling
        guard pasteboard.hasStrings else {
            // No string content available
            if url != nil {
                DispatchQueue.main.async {
                    self.url = nil
                }
            }
            return
        }
        
        let currentChangeCount = pasteboard.changeCount
        
        // Only check if clipboard content has changed
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Safely get clipboard string
            guard let clipboardString = pasteboard.string else {
                DispatchQueue.main.async {
                    self.url = nil
                }
                return
            }
            
            // Avoid processing the same URL repeatedly
            if clipboardString == lastKnownURL {
                return
            }
            
            let extractedURL = extractYouTubeURL(from: clipboardString)
            lastKnownURL = clipboardString
            
            DispatchQueue.main.async {
                self.url = extractedURL
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
