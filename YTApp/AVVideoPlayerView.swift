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
        
        // Set up the player with demonstration content
        setupPlayer(for: controller, context: context)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update player if video ID changes
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            setupPlayer(for: uiViewController, context: context)
        }
    }
    
    private func setupPlayer(for controller: AVPlayerViewController, context: Context) {
        // Configure audio session for background playback
        configureAudioSession()
        
        // For demonstration purposes, we'll use Apple's sample video
        // In production, you would need to:
        // 1. Use YouTube Data API to get video metadata
        // 2. Use youtube-dl, yt-dlp, or similar service to extract direct video URLs
        // 3. Handle different video qualities and formats
        
        let demoURL = createDemoURL(for: videoID)
        
        // Create AVPlayer
        let player = AVPlayer(url: demoURL)
        controller.player = player
        
        // Set up player observers
        setupPlayerObservers(player: player, context: context)
        
        // Start playback
        player.play()
        
        // Show demo message after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showDemoAlert(on: controller)
        }
    }
    
    private func createDemoURL(for videoID: String) -> URL {
        // Using Apple's sample video for demonstration
        // This shows that AVKit player works, but YouTube requires special handling
        return URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8") ?? URL(string: "https://www.apple.com")!
    }
    
    private func showDemoAlert(on controller: AVPlayerViewController) {
        let alert = UIAlertController(
            title: "AVKit Demo Mode",
            message: "This is playing a sample video to demonstrate Picture-in-Picture capabilities.\n\nYouTube videos require direct stream URLs which need special extraction services in production apps.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        
        controller.present(alert, animated: true)
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
        var currentVideoID: String = ""
        
        init(onPlaybackStarted: (() -> Void)?) {
            self.onPlaybackStarted = onPlaybackStarted
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "status", let player = object as? AVPlayer {
                switch player.status {
                case .readyToPlay:
                    print("✅ AVPlayer ready to play (demo content)")
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
