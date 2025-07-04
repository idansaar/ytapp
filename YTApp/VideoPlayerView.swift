import SwiftUI
import WebKit

// MARK: - Main SwiftUI View with Loading States
struct VideoPlayerView: View {
    let videoID: String
    let onPlaybackStarted: (() -> Void)?
    let playbackPositionManager: PlaybackPositionManager?
    let errorManager: ErrorManager?
    
    @State private var isLoading = true
    @State private var hasError = false
    
    init(videoID: String, onPlaybackStarted: (() -> Void)? = nil, playbackPositionManager: PlaybackPositionManager? = nil, errorManager: ErrorManager? = nil) {
        print("🌐 [DEBUG] VideoPlayerView init - videoID: \(videoID)")
        self.videoID = videoID
        self.onPlaybackStarted = onPlaybackStarted
        self.playbackPositionManager = playbackPositionManager
        self.errorManager = errorManager
    }
    
    var body: some View {
        ZStack {
            // WebKit Player
            WebKitVideoPlayer(
                videoID: videoID,
                onPlaybackStarted: onPlaybackStarted,
                playbackPositionManager: playbackPositionManager,
                errorManager: errorManager,
                isLoading: $isLoading,
                hasError: $hasError
            )
            
            // Loading Overlay
            if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            Text("Loading Video...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    )
            }
            
            // Error Overlay
            if hasError && !isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            Text("Failed to Load Video")
                                .foregroundColor(.primary)
                                .font(.headline)
                            
                            Text("Please check your connection and try again")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                isLoading = true
                                hasError = false
                                // The WebKit view will automatically reload
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    )
            }
        }
        .onAppear {
            isLoading = true
            hasError = false
        }
        .onChange(of: videoID) { oldValue, newValue in
            isLoading = true
            hasError = false
        }
    }
}

// MARK: - WebKit UIViewRepresentable
struct WebKitVideoPlayer: UIViewRepresentable {
    let videoID: String
    let onPlaybackStarted: (() -> Void)?
    let playbackPositionManager: PlaybackPositionManager?
    let errorManager: ErrorManager?
    @Binding var isLoading: Bool
    @Binding var hasError: Bool
    
    init(videoID: String, onPlaybackStarted: (() -> Void)? = nil, playbackPositionManager: PlaybackPositionManager? = nil, errorManager: ErrorManager? = nil, isLoading: Binding<Bool>, hasError: Binding<Bool>) {
        self.videoID = videoID
        self.onPlaybackStarted = onPlaybackStarted
        self.playbackPositionManager = playbackPositionManager
        self.errorManager = errorManager
        self._isLoading = isLoading
        self._hasError = hasError
    }

    func makeUIView(context: Context) -> WKWebView {
        print("🌐 [DEBUG] WebKit makeUIView called for videoID: \(videoID)")
        let configuration = WKWebViewConfiguration()
        
        // Configure for media playback
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Disable features that might cause assertion errors in simulator
        if #available(iOS 15.0, *) {
            configuration.upgradeKnownHostsToHTTPS = false
        }
        
        // Add message handlers
        configuration.userContentController.add(context.coordinator, name: "videoObserver")
        configuration.userContentController.add(context.coordinator, name: "playbackStarted")
        configuration.userContentController.add(context.coordinator, name: "errorHandler")
        configuration.userContentController.add(context.coordinator, name: "positionUpdate")
        configuration.userContentController.add(context.coordinator, name: "playerReady")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        
        // Store webView reference in coordinator
        context.coordinator.webView = webView
        
        // Configure for simulator
        #if targetEnvironment(simulator)
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.configuration.preferences.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        #endif
        
        // Store the callback in coordinator
        context.coordinator.onPlaybackStarted = onPlaybackStarted
        context.coordinator.playbackPositionManager = playbackPositionManager
        
        // Load the HTML content immediately
        let html = createHTML(for: videoID)
        webView.loadHTMLString(html, baseURL: nil)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only update if the video ID has actually changed
        // This prevents constant reloading
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            context.coordinator.onPlaybackStarted = onPlaybackStarted
            context.coordinator.playbackPositionManager = playbackPositionManager
            
            let html = createHTML(for: videoID)
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    private func createHTML(for videoID: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background-color: black;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                .video-container {
                    width: 100%;
                    height: 100%;
                    position: relative;
                }
                #youtube-player {
                    width: 100%;
                    height: 100%;
                    border: none;
                }
                .loading {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    color: white;
                    text-align: center;
                    z-index: 10;
                }
                .error-message {
                    color: white;
                    text-align: center;
                    padding: 20px;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <div class="loading" id="loading">
                    <div>🎬</div>
                    <div>Loading Video...</div>
                    <div style="font-size: 12px; margin-top: 10px;">Video ID: \(videoID)</div>
                </div>
                <div id="youtube-player"></div>
            </div>
            
            <script>
                console.log('🌐 [DEBUG] Initializing WebKit player for: \(videoID)');
                
                var player;
                var playbackNotified = false;
                var positionTimer;
                var currentVideoID = '\(videoID)';
                
                // Load YouTube IFrame Player API
                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                var firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
                
                // YouTube API ready callback
                function onYouTubeIframeAPIReady() {
                    console.log('🌐 [DEBUG] YouTube API ready');
                    
                    player = new YT.Player('youtube-player', {
                        height: '100%',
                        width: '100%',
                        videoId: currentVideoID,
                        playerVars: {
                            'autoplay': 1,
                            'controls': 1,
                            'playsinline': 1,
                            'rel': 0,
                            'modestbranding': 1,
                            'enablejsapi': 1
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange,
                            'onError': onPlayerError
                        }
                    });
                }
                
                function onPlayerReady(event) {
                    console.log('🌐 [DEBUG] Player ready for: ' + currentVideoID);
                    
                    // Hide loading
                    var loading = document.getElementById('loading');
                    if (loading) loading.style.display = 'none';
                    
                    // Notify WebKit that player is ready (for resume functionality)
                    if (window.webkit && window.webkit.messageHandlers) {
                        if (window.webkit.messageHandlers.playerReady) {
                            window.webkit.messageHandlers.playerReady.postMessage(currentVideoID);
                        }
                        
                        if (window.webkit.messageHandlers.videoObserver) {
                            window.webkit.messageHandlers.videoObserver.postMessage('YouTube Video ' + currentVideoID);
                        }
                    }
                }
                
                function onPlayerStateChange(event) {
                    console.log('🌐 [DEBUG] Player state changed: ' + event.data);
                    
                    if (event.data == YT.PlayerState.PLAYING) {
                        console.log('🌐 [DEBUG] Video started playing: ' + currentVideoID);
                        
                        // Notify playback started (only once)
                        if (!playbackNotified && window.webkit && window.webkit.messageHandlers) {
                            if (window.webkit.messageHandlers.playbackStarted) {
                                window.webkit.messageHandlers.playbackStarted.postMessage(currentVideoID);
                                playbackNotified = true;
                            }
                        }
                        
                        // Start position tracking
                        startPositionTracking();
                        
                    } else if (event.data == YT.PlayerState.PAUSED || 
                               event.data == YT.PlayerState.ENDED) {
                        // Stop position tracking
                        stopPositionTracking();
                    }
                }
                
                function startPositionTracking() {
                    console.log('🌐 [DEBUG] Starting position tracking');
                    
                    // Clear any existing timer
                    stopPositionTracking();
                    
                    // Track position every 5 seconds
                    positionTimer = setInterval(function() {
                        if (player && player.getCurrentTime && player.getDuration) {
                            var currentTime = player.getCurrentTime();
                            var duration = player.getDuration();
                            
                            if (currentTime > 0 && duration > 0) {
                                console.log('🌐 [DEBUG] Position update - ' + currentTime.toFixed(1) + 's / ' + duration.toFixed(1) + 's');
                                
                                // Send position to WebKit
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.positionUpdate) {
                                    window.webkit.messageHandlers.positionUpdate.postMessage({
                                        videoId: currentVideoID,
                                        position: currentTime,
                                        duration: duration,
                                        progress: (currentTime / duration) * 100
                                    });
                                }
                            }
                        }
                    }, 5000); // Every 5 seconds
                }
                
                function stopPositionTracking() {
                    if (positionTimer) {
                        console.log('🌐 [DEBUG] Stopping position tracking');
                        clearInterval(positionTimer);
                        positionTimer = null;
                    }
                }
                
                function onPlayerError(event) {
                    console.error('🌐 [DEBUG] Player error: ' + event.data);
                    
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.errorHandler) {
                        window.webkit.messageHandlers.errorHandler.postMessage('Player error: ' + event.data + ' for video: ' + currentVideoID);
                    }
                }
                
                // Cleanup on page unload
                window.addEventListener('beforeunload', function() {
                    stopPositionTracking();
                });
            </script>
        </body>
        </html>
        """
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var onPlaybackStarted: (() -> Void)?
        var currentVideoID: String = ""
        var playbackPositionManager: PlaybackPositionManager?
        weak var webView: WKWebView?
        var parent: WebKitVideoPlayer
        
        init(parent: WebKitVideoPlayer) {
            self.parent = parent
            self.playbackPositionManager = parent.playbackPositionManager
            super.init()
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("🌐 [DEBUG] WebKit received message: \(message.name) - body: \(message.body)")
            
            switch message.name {
            case "videoObserver":
                if let title = message.body as? String {
                    print("🎬 Video Title: \(title)")
                }
            case "playerReady":
                if let videoID = message.body as? String {
                    print("🌐 [DEBUG] Player ready for: \(videoID)")
                    
                    // Update loading state
                    DispatchQueue.main.async {
                        self.parent.isLoading = false
                        self.parent.hasError = false
                    }
                    
                    // Check for saved position and seek if needed
                    DispatchQueue.main.async {
                        self.handlePlayerReady(videoID: videoID)
                    }
                }
            case "playbackStarted":
                if let videoID = message.body as? String {
                    print("▶️ Playback started for video: \(videoID)")
                    DispatchQueue.main.async {
                        self.onPlaybackStarted?()
                    }
                }
            case "positionUpdate":
                if let positionData = message.body as? [String: Any],
                   let videoId = positionData["videoId"] as? String,
                   let position = positionData["position"] as? Double,
                   let duration = positionData["duration"] as? Double,
                   let progress = positionData["progress"] as? Double {
                    
                    print("🌐 [DEBUG] Position update - \(String(format: "%.1f", position))s/\(String(format: "%.1f", duration))s (\(String(format: "%.1f", progress))%)")
                    
                    // Save position using PlaybackPositionManager
                    DispatchQueue.main.async {
                        self.playbackPositionManager?.savePosition(
                            videoID: videoId,
                            position: position,
                            duration: duration
                        )
                    }
                }
            case "errorHandler":
                if let errorMessage = message.body as? String {
                    print("❌ Video Player Error: \(errorMessage)")
                    
                    // Report error to ErrorManager
                    self.parent.errorManager?.reportVideoLoadError(errorMessage, context: "WebKit Player")
                    
                    // Update error state
                    DispatchQueue.main.async {
                        self.parent.isLoading = false
                        self.parent.hasError = true
                    }
                }
            default:
                print("🌐 [DEBUG] Unknown message: \(message.name)")
                break
            }
        }
        
        private func handlePlayerReady(videoID: String) {
            guard let webView = self.webView else { 
                print("❌ [DEBUG] No webView reference available")
                return 
            }
            
            // Check if we should resume from saved position
            if let savedPosition = playbackPositionManager?.getPosition(for: videoID) {
                let seekTime = savedPosition.position
                print("🌐 [DEBUG] Resuming video \(videoID) from saved position: \(savedPosition.formattedPosition) (\(seekTime) seconds)")
                
                // Seek to saved position using JavaScript
                let seekScript = "if (player && player.seekTo) { player.seekTo(\(seekTime), true); console.log('🌐 [DEBUG] Seeked to: \(seekTime)s'); }"
                webView.evaluateJavaScript(seekScript) { result, error in
                    if let error = error {
                        print("❌ [DEBUG] Seek error: \(error.localizedDescription)")
                    } else {
                        print("✅ [DEBUG] Successfully seeked to \(String(format: "%.1f", seekTime))s")
                    }
                }
            } else {
                print("🌐 [DEBUG] Starting video \(videoID) from beginning (no saved position)")
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView navigation error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow all navigation for YouTube embeds
            decisionHandler(.allow)
        }
    }
}
