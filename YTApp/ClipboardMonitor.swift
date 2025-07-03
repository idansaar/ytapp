import Foundation
import UIKit

class ClipboardMonitor: ObservableObject {
    @Published var hasYouTubeURL = false
    @Published var detectedURL: String?
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    func startMonitoring() {
        lastChangeCount = UIPasteboard.general.changeCount
        checkClipboard()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let currentChangeCount = UIPasteboard.general.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let clipboardString = UIPasteboard.general.string {
                let isYouTubeURL = isValidYouTubeURL(clipboardString)
                
                DispatchQueue.main.async {
                    self.hasYouTubeURL = isYouTubeURL
                    self.detectedURL = isYouTubeURL ? clipboardString : nil
                }
            } else {
                DispatchQueue.main.async {
                    self.hasYouTubeURL = false
                    self.detectedURL = nil
                }
            }
        }
    }
    
    private func isValidYouTubeURL(_ urlString: String) -> Bool {
        let youtubePatterns = [
            "youtube.com/watch",
            "youtu.be/",
            "m.youtube.com/watch",
            "youtube.com/embed/",
            "youtube.com/v/"
        ]
        
        let lowercaseURL = urlString.lowercased()
        return youtubePatterns.contains { pattern in
            lowercaseURL.contains(pattern)
        }
    }
}
