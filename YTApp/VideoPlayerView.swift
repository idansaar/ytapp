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
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.configuration.userContentController.add(context.coordinator, name: "videoObserver")
        webView.configuration.userContentController.add(context.coordinator, name: "playbackStarted")
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update the coordinator with the callback
        context.coordinator.onPlaybackStarted = onPlaybackStarted
        
        let html = """
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
                }
                #player {
                    width: 100%;
                    height: 100%;
                }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script>
                var player;
                var playbackStarted = false;
                
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        height: '100%',
                        width: '100%',
                        videoId: '\(videoID)',
                        playerVars: {
                            'playsinline': 1,
                            'autoplay': 1,
                            'controls': 1,
                            'rel': 0,
                            'modestbranding': 1,
                            'fs': 1
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange
                        }
                    });
                }
                
                function onPlayerReady(event) {
                    // Auto-play the video when ready
                    event.target.playVideo();
                    event.target.unMute();
                    
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoObserver) {
                        window.webkit.messageHandlers.videoObserver.postMessage(player.getVideoData().title);
                    }
                }
                
                function onPlayerStateChange(event) {
                    // YT.PlayerState.PLAYING = 1
                    if (event.data === 1 && !playbackStarted) {
                        playbackStarted = true;
                        console.log('🎬 Playback started for video: \(videoID)');
                        
                        // Notify Swift that playback has started
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.playbackStarted) {
                            window.webkit.messageHandlers.playbackStarted.postMessage('\(videoID)');
                        }
                    }
                }
            </script>
            <script src="https://www.youtube.com/iframe_api"></script>
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var onPlaybackStarted: (() -> Void)?
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "videoObserver" {
                if let title = message.body as? String {
                    print("🎬 Video Title: \(title)")
                }
            } else if message.name == "playbackStarted" {
                if let videoID = message.body as? String {
                    print("▶️ Playback started for video: \(videoID)")
                    onPlaybackStarted?()
                }
            }
        }
    }
}
