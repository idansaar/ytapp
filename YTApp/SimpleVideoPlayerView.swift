import SwiftUI
import AVKit
import AVFoundation

struct SimpleVideoPlayerView: UIViewControllerRepresentable {
    let videoID: String
    let onPlaybackStarted: (() -> Void)?
    
    init(videoID: String, onPlaybackStarted: (() -> Void)? = nil) {
        self.videoID = videoID
        self.onPlaybackStarted = onPlaybackStarted
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        // Create YouTube URL (this will show YouTube's web player)
        _ = URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
        
        // For now, we'll use a placeholder video URL since direct YouTube streaming requires special handling
        // In production, you'd need youtube-dl or similar service to get the actual stream URL
        let placeholderURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
        
        let player = AVPlayer(url: placeholderURL)
        controller.player = player
        
        // Configure for inline playback
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = false
        
        // Set up observer for playback
        context.coordinator.setupPlaybackObserver(player: player, onPlaybackStarted: onPlaybackStarted)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        private var timeObserver: Any?
        
        func setupPlaybackObserver(player: AVPlayer, onPlaybackStarted: (() -> Void)?) {
            // Observe when playback actually starts
            timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: .main) { time in
                if time.seconds > 0 && player.rate > 0 {
                    // Playback has started
                    onPlaybackStarted?()
                    
                    // Remove observer after first callback
                    if let observer = self.timeObserver {
                        player.removeTimeObserver(observer)
                        self.timeObserver = nil
                    }
                }
            }
        }
        
        deinit {
            if timeObserver != nil {
                // Clean up observer
            }
        }
    }
}
