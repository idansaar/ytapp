import SwiftUI
import AVFoundation

@main
struct YTAppApp: App {
    
    init() {
        // Configure background playback on app launch
        configureBackgroundPlayback()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureBackgroundPlayback() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
            print("🔊 Background playback configured successfully")
        } catch {
            print("❌ Failed to configure background playback: \(error)")
        }
    }
}
