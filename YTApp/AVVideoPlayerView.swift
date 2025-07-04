import SwiftUI
import AVKit
import AVFoundation

struct AVVideoPlayerView: UIViewControllerRepresentable {
    let videoID: String
    let playbackPositionManager: PlaybackPositionManager
    let startFromBeginning: Bool
    let onPlaybackStarted: (() -> Void)?
    let onPlaybackPositionChanged: ((Double, Double) -> Void)?
    
    init(videoID: String, playbackPositionManager: PlaybackPositionManager, startFromBeginning: Bool = false, onPlaybackStarted: (() -> Void)? = nil, onPlaybackPositionChanged: ((Double, Double) -> Void)? = nil) {
        self.videoID = videoID
        self.playbackPositionManager = playbackPositionManager
        self.startFromBeginning = startFromBeginning
        self.onPlaybackStarted = onPlaybackStarted
        self.onPlaybackPositionChanged = onPlaybackPositionChanged
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
        
        // Setup coordinator with player for position tracking
        context.coordinator.setupPlayer(player, for: videoID)
        
        // Start playback
        player.play()
        
        // Show demo message after video starts playing (longer delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // Only show alert if the player is still active and ready
            if player.status == .readyToPlay {
                self.showDemoAlert(on: controller)
            }
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
            message: "This demonstrates Picture-in-Picture and background playback capabilities using sample content.\n\nFor YouTube videos, production apps need youtube-dl or similar services to extract direct video URLs.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        alert.addAction(UIAlertAction(title: "Don't show again", style: .cancel) { _ in
            // Store preference to not show this alert again
            UserDefaults.standard.set(true, forKey: "AVKitDemoAlertShown")
        })
        
        // Only show if user hasn't dismissed it before
        if !UserDefaults.standard.bool(forKey: "AVKitDemoAlertShown") {
            controller.present(alert, animated: true)
        }
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
        Coordinator(
            playbackPositionManager: playbackPositionManager,
            startFromBeginning: startFromBeginning,
            onPlaybackStarted: onPlaybackStarted,
            onPlaybackPositionChanged: onPlaybackPositionChanged
        )
    }
    
    class Coordinator: NSObject {
        let onPlaybackStarted: (() -> Void)?
        let onPlaybackPositionChanged: ((Double, Double) -> Void)?
        let playbackPositionManager: PlaybackPositionManager
        let startFromBeginning: Bool
        var hasNotifiedPlaybackStart = false
        var currentVideoID: String = ""
        var timeObserver: Any?
        var player: AVPlayer?
        
        init(playbackPositionManager: PlaybackPositionManager, startFromBeginning: Bool, onPlaybackStarted: (() -> Void)?, onPlaybackPositionChanged: ((Double, Double) -> Void)?) {
            self.playbackPositionManager = playbackPositionManager
            self.startFromBeginning = startFromBeginning
            self.onPlaybackStarted = onPlaybackStarted
            self.onPlaybackPositionChanged = onPlaybackPositionChanged
            super.init()
        }
        
        deinit {
            removeTimeObserver()
        }
        
        func setupPlayer(_ player: AVPlayer, for videoID: String) {
            self.player = player
            self.currentVideoID = videoID
            
            // Add time observer for position tracking
            addTimeObserver()
            
            // Restore playback position if not starting from beginning
            if !startFromBeginning, let savedPosition = playbackPositionManager.getPosition(for: videoID) {
                let seekTime = CMTime(seconds: savedPosition.position, preferredTimescale: 1000)
                player.seek(to: seekTime) { completed in
                    if completed {
                        print("▶️ Resumed playback at \(savedPosition.formattedPosition)")
                    }
                }
            }
        }
        
        private func addTimeObserver() {
            guard let player = player else { return }
            
            // Remove existing observer
            removeTimeObserver()
            
            // Add periodic time observer (every 5 seconds)
            let interval = CMTime(seconds: 5.0, preferredTimescale: 1000)
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                self?.handleTimeUpdate(time)
            }
        }
        
        private func removeTimeObserver() {
            if let observer = timeObserver, let player = player {
                player.removeTimeObserver(observer)
                timeObserver = nil
            }
        }
        
        private func handleTimeUpdate(_ time: CMTime) {
            guard let player = player,
                  let duration = player.currentItem?.duration,
                  duration.isValid && !duration.isIndefinite else { return }
            
            let currentTime = time.seconds
            let totalDuration = duration.seconds
            
            // Save position every 5 seconds
            if currentTime > 0 && totalDuration > 0 {
                playbackPositionManager.savePosition(
                    videoID: currentVideoID,
                    position: currentTime,
                    duration: totalDuration
                )
                
                // Notify callback
                onPlaybackPositionChanged?(currentTime, totalDuration)
            }
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "status", let player = object as? AVPlayer {
                switch player.status {
                case .readyToPlay:
                    print("✅ AVPlayer ready to play (demo content)")
                    if !hasNotifiedPlaybackStart {
                        onPlaybackStarted?()
                        hasNotifiedPlaybackStart = true
                    }
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
