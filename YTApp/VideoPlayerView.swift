import SwiftUI
import WebKit

struct VideoPlayerView: UIViewRepresentable {
    let videoID: String
    let onPlaybackStarted: (() -> Void)?
    
    init(videoID: String, onPlaybackStarted: (() -> Void)? = nil) {
        self.videoID = videoID
        self.onPlaybackStarted = onPlaybackStarted
    }

    func makeUIView(context: Context) -> WKWebView {
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
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        
        // Configure for simulator
        #if targetEnvironment(simulator)
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.configuration.preferences.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        #endif
        
        // Store the callback in coordinator
        context.coordinator.onPlaybackStarted = onPlaybackStarted
        
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
                iframe {
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
                <iframe 
                    id="youtube-player"
                    src="https://www.youtube.com/embed/\(videoID)?autoplay=1&controls=1&playsinline=1&rel=0&modestbranding=1&enablejsapi=1&origin=https://localhost"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowfullscreen
                    style="display: none;">
                </iframe>
            </div>
            
            <script>
                console.log('🎬 Initializing video player for: \(videoID)');
                var playbackNotified = false;
                
                // Show iframe and hide loading after a short delay
                setTimeout(function() {
                    var loading = document.getElementById('loading');
                    var iframe = document.getElementById('youtube-player');
                    
                    if (loading) loading.style.display = 'none';
                    if (iframe) iframe.style.display = 'block';
                    
                    console.log('🎬 Video iframe displayed for: \(videoID)');
                    
                    // Notify that video is ready
                    if (window.webkit && window.webkit.messageHandlers) {
                        if (window.webkit.messageHandlers.videoObserver) {
                            window.webkit.messageHandlers.videoObserver.postMessage('YouTube Video \(videoID)');
                        }
                        
                        // Simulate playback start after iframe loads (only once)
                        if (!playbackNotified) {
                            setTimeout(function() {
                                if (window.webkit.messageHandlers.playbackStarted) {
                                    console.log('🎬 Notifying playback start for: \(videoID)');
                                    window.webkit.messageHandlers.playbackStarted.postMessage('\(videoID)');
                                    playbackNotified = true;
                                }
                            }, 3000); // Wait 3 seconds for video to start
                        }
                    }
                }, 1000);
                
                // Error handling for iframe load failures
                document.getElementById('youtube-player').onerror = function() {
                    console.error('Failed to load YouTube iframe for: \(videoID)');
                    document.querySelector('.video-container').innerHTML = 
                        '<div class="error-message">' +
                        '<h3>⚠️ Video Load Error</h3>' +
                        '<p>Unable to load video player</p>' +
                        '<p>Video ID: \(videoID)</p>' +
                        '<p style="font-size: 12px;">Check your internet connection</p>' +
                        '</div>';
                        
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.errorHandler) {
                        window.webkit.messageHandlers.errorHandler.postMessage('Failed to load video iframe for \(videoID)');
                    }
                };
                
                // Prevent page from reloading
                window.addEventListener('beforeunload', function(e) {
                    e.preventDefault();
                    return false;
                });
            </script>
        </body>
        </html>
        """
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var onPlaybackStarted: (() -> Void)?
        var currentVideoID: String = ""
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "videoObserver":
                if let title = message.body as? String {
                    print("🎬 Video Title: \(title)")
                }
            case "playbackStarted":
                if let videoID = message.body as? String {
                    print("▶️ Playback started for video: \(videoID)")
                    DispatchQueue.main.async {
                        self.onPlaybackStarted?()
                    }
                }
            case "errorHandler":
                if let errorMessage = message.body as? String {
                    print("❌ Video Player Error: \(errorMessage)")
                }
            default:
                break
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
