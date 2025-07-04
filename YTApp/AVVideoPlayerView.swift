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
        
        print("🎬 [DEBUG] Setting up AVKit player for YouTube video: \(videoID)")
        
        // For now, we'll use a fallback approach since YouTube direct URLs require special extraction
        // Option 1: Try to extract YouTube URL (would need youtube-dl in production)
        // Option 2: Use a sample video that demonstrates AVKit capabilities
        // Option 3: Show an error message explaining the limitation
        
        let videoURL = getVideoURL(for: videoID)
        
        // Create AVPlayer
        let player = AVPlayer(url: videoURL)
        controller.player = player
        
        // Set up player observers
        setupPlayerObservers(player: player, context: context)
        
        // Setup coordinator with player for position tracking
        context.coordinator.setupPlayer(player, for: videoID)
        
        // Start playback
        player.play()
        
        print("✅ [DEBUG] AVKit player setup complete for video: \(videoID)")
    }
    
    private func getVideoURL(for videoID: String) -> URL {
        // In a production app, you would:
        // 1. Use youtube-dl/yt-dlp to extract direct video URLs
        // 2. Set up a backend service to handle URL extraction
        // 3. Use services like Invidious that provide direct URLs
        
        // For now, we'll use different sample videos based on the YouTube video ID
        // This demonstrates that AVKit works while showing the YouTube integration challenge
        
        let sampleVideos = [
            "dQw4w9WgXcQ": "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8", // Rick Roll -> Apple sample
            "9bZkp7q19f0": "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4", // Gangnam Style -> Sample video
            "kJQP7kiw5Fk": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", // Despacito -> Big Buck Bunny
        ]
        
        // Use specific sample video for known YouTube IDs, otherwise use default
        let urlString = sampleVideos[videoID] ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
        
        print("🎬 [DEBUG] Using sample video URL for \(videoID): \(urlString)")
        print("ℹ️ [DEBUG] Note: Production apps need youtube-dl/yt-dlp for real YouTube URLs")
        
        return URL(string: urlString) ?? URL(string: "https://www.apple.com")!
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
            print("🎮 [DEBUG] setupPlayer called for videoID: \(videoID)")
            self.player = player
            self.currentVideoID = videoID
            
            // Add time observer for position tracking
            addTimeObserver()
            
            // Restore playback position if not starting from beginning
            if !startFromBeginning, let savedPosition = playbackPositionManager.getPosition(for: videoID) {
                print("🎬 [DEBUG] Starting video \(videoID) from saved position: \(savedPosition.formattedPosition) (\(savedPosition.position) seconds)")
                let seekTime = CMTime(seconds: savedPosition.position, preferredTimescale: 1000)
                player.seek(to: seekTime) { completed in
                    if completed {
                        print("▶️ [DEBUG] Successfully resumed playback at \(savedPosition.formattedPosition)")
                    } else {
                        print("❌ [DEBUG] Failed to seek to saved position for video \(videoID)")
                    }
                }
            } else {
                if startFromBeginning {
                    print("🎬 [DEBUG] Starting video \(videoID) from beginning (startFromBeginning = true)")
                } else {
                    print("🎬 [DEBUG] Starting video \(videoID) from beginning (no saved position found)")
                }
            }
        }
        
        private func addTimeObserver() {
            guard let player = player else { 
                print("❌ [DEBUG] Cannot add time observer - no player")
                return 
            }
            
            print("🎯 [DEBUG] Adding time observer for position tracking")
            
            // Remove existing observer
            removeTimeObserver()
            
            // Add periodic time observer (every 5 seconds)
            let interval = CMTime(seconds: 5.0, preferredTimescale: 1000)
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                self?.handleTimeUpdate(time)
            }
            
            print("✅ [DEBUG] Time observer added successfully - will fire every 5 seconds")
        }
        
        private func removeTimeObserver() {
            if let observer = timeObserver, let player = player {
                print("🗑️ [DEBUG] Removing existing time observer")
                player.removeTimeObserver(observer)
                timeObserver = nil
            } else {
                print("ℹ️ [DEBUG] No time observer to remove")
            }
        }
        
        private func handleTimeUpdate(_ time: CMTime) {
            print("🕐 [DEBUG] handleTimeUpdate called - Time: \(String(format: "%.1f", time.seconds))s")
            
            guard let player = player,
                  let duration = player.currentItem?.duration,
                  duration.isValid && !duration.isIndefinite else { 
                print("🚫 [DEBUG] handleTimeUpdate early return - Invalid player/duration")
                return 
            }
            
            let currentTime = time.seconds
            let totalDuration = duration.seconds
            
            print("📊 [DEBUG] Time update - Current: \(String(format: "%.1f", currentTime))s, Duration: \(String(format: "%.1f", totalDuration))s")
            
            // Save position every 5 seconds
            if currentTime > 0 && totalDuration > 0 {
                playbackPositionManager.savePosition(
                    videoID: currentVideoID,
                    position: currentTime,
                    duration: totalDuration
                )
                print("⏱️ [DEBUG] Updated position for \(currentVideoID): \(Int(currentTime))s/\(Int(totalDuration))s (\(String(format: "%.1f", (currentTime/totalDuration)*100))%)")
                
                // Notify callback
                onPlaybackPositionChanged?(currentTime, totalDuration)
            } else {
                print("⏸️ [DEBUG] Skipping position save - Current: \(String(format: "%.1f", currentTime))s, Duration: \(String(format: "%.1f", totalDuration))s")
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
