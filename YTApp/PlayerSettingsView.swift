import SwiftUI

struct PlayerSettingsView: View {
    @Binding var useAVPlayer: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Video Player")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // WebKit Player Option
                        HStack {
                            VStack(alignment: .leading) {
                                Text("WebKit Player")
                                    .font(.headline)
                                Text("Web-based YouTube embed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if !useAVPlayer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            useAVPlayer = false
                        }
                        
                        Divider()
                        
                        // AVKit Player Option
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("AVKit Player")
                                        .font(.headline)
                                    Text("NEW")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                Text("Native player with Picture-in-Picture")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if useAVPlayer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            useAVPlayer = true
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Features")) {
                    FeatureRow(
                        icon: "safari",
                        title: "YouTube Compatibility",
                        description: "Plays actual YouTube videos",
                        available: !useAVPlayer
                    )
                    
                    FeatureRow(
                        icon: "play.rectangle",
                        title: "Demo Content",
                        description: "Uses AVKit with PiP support and position tracking",
                        available: useAVPlayer
                    )
                    
                    FeatureRow(
                        icon: "pip",
                        title: "Picture-in-Picture",
                        description: "Continue watching while using other apps",
                        available: useAVPlayer
                    )
                    
                    FeatureRow(
                        icon: "speaker.wave.2",
                        title: "Background Audio",
                        description: "Audio continues when app is backgrounded",
                        available: useAVPlayer
                    )
                    
                    FeatureRow(
                        icon: "airplayaudio",
                        title: "AirPlay Support",
                        description: "Stream to Apple TV and other devices",
                        available: useAVPlayer
                    )
                }
                
                Section(footer: Text("Note: AVKit player uses sample videos mapped to YouTube IDs since YouTube doesn't provide direct video URLs. For production apps, services like youtube-dl/yt-dlp would extract real YouTube video streams.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Player Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let available: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(available ? .blue : .gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(available ? .primary : .secondary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if available {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: "minus.circle")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PlayerSettingsView(useAVPlayer: .constant(false))
}
