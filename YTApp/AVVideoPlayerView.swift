import SwiftUI
import AVKit
import AVFoundation

struct AVVideoPlayerView: UIViewControllerRepresentable {
    let videoID: String
    let onPlaybackStarted: (() -> Void)?
    
    init(videoID: String, onPlaybackStarted: (() -> Void)? = nil) {
        self.videoID = videoID
        self.onPlaybackStarted = onPlaybackStarted
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        // Configure for Picture-in-Picture
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        
        // Set up the player with YouTube URL
        setupPlayer(for: controller, context: context)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update player if video ID changes
        if let currentURL = uiViewController.player?.currentItem?.asset as? AVURLAsset,
           !currentURL.url.absoluteString.contains(videoID) {
            setupPlayer(for: uiViewController, context: context)
        }
    }
    
    private func setupPlayer(for controller: AVPlayerViewController, context: Context) {
        // Configure audio session for background playback
        configureAudioSession()
        
        // Create YouTube URL - using direct video URL for AVPlayer
        // Note: In production, you'd use youtube-dl or similar service to get direct video URLs
        // For now, we'll use a placeholder approach
        let youtubeURL = createYouTubeURL(for: videoID)
        
        // Create AVPlayer
        let player = AVPlayer(url: youtubeURL)
        controller.player = player
        
        // Set up player observers
        setupPlayerObservers(player: player, context: context)
        
        // Start playback
        player.play()
    }
    
    private func createYouTubeURL(for videoID: String) -> URL {
        // This is a placeholder - in production you'd need to:
        // 1. Use YouTube Data API to get video info
        // 2. Use youtube-dl or similar to extract direct video URLs
        // 3. Handle different quality options
        
        // For now, return a placeholder URL that won't work but demonstrates the structure
        // In a real app, this would be replaced with actual video stream URLs
        return URL(string: "https://www.youtube.com/watch?v=\(videoID)") ?? URL(string: "https://www.apple.com")!
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for playback with background support
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
            
            print("🔊 Audio session configured for background playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    private func setupPlayerObservers(player: AVPlayer, context: Context) {
        // Observe player status
        player.addObserver(context.coordinator, forKeyPath: "status", options: [.new], context: nil)
        
        // Observe playback start
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            print("🎬 Video playback completed")
        }
        
        // Observe when playback actually starts
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            if time.seconds > 0 && context.coordinator.hasNotifiedPlaybackStart == false {
                context.coordinator.hasNotifiedPlaybackStart = true
                context.coordinator.onPlaybackStarted?()
                print("🎯 AVPlayer playback started, notifying history manager")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPlaybackStarted: onPlaybackStarted)
    }
    
    class Coordinator: NSObject {
        let onPlaybackStarted: (() -> Void)?
        var hasNotifiedPlaybackStart = false
        
        init(onPlaybackStarted: (() -> Void)?) {
            self.onPlaybackStarted = onPlaybackStarted
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "status", let player = object as? AVPlayer {
                switch player.status {
                case .readyToPlay:
                    print("✅ AVPlayer ready to play")
                case .failed:
                    print("❌ AVPlayer failed: \(player.error?.localizedDescription ?? "Unknown error")")
                case .unknown:
                    print("⏳ AVPlayer status unknown")
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - Background Playback Configuration
extension AVVideoPlayerView {
    static func configureBackgroundPlayback() {
        // This should be called in the App delegate or main app setup
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
            
            // Enable background app refresh (requires Info.plist configuration)
            print("🔊 Background playback configured")
        } catch {
            print("❌ Failed to configure background playback: \(error)")
        }
    }
}
