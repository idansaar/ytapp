import SwiftUI

struct DebugView: View {
    @State private var debugOutput = "Debug Output:\n"
    @State private var testChannelURL = "https://www.youtube.com/@mkbhd"
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("YTApp Debug Console")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Configuration Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configuration Status:")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: Config.isYouTubeAPIConfigured ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(Config.isYouTubeAPIConfigured ? .green : .red)
                        Text("YouTube API Key: \(Config.isYouTubeAPIConfigured ? "Configured" : "Missing")")
                    }
                    
                    if let validationError = Config.validateConfiguration() {
                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Test Channel URL Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Channel URL:")
                        .font(.headline)
                    
                    TextField("Enter YouTube channel URL", text: $testChannelURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: testChannelFetch) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Testing..." : "Test Channel Fetch")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading)
                }
                
                // Debug Output
                ScrollView {
                    Text(debugOutput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
        }
    }
    
    private func testChannelFetch() {
        isLoading = true
        appendDebug("🧪 Starting channel fetch test...")
        appendDebug("URL: \(testChannelURL)")
        appendDebug("API Key configured: \(Config.isYouTubeAPIConfigured)")
        
        Task {
            do {
                appendDebug("🔄 Attempting to fetch channel...")
                let channel = try await YouTubeAPIService.shared.getChannelFromURL(testChannelURL)
                
                await MainActor.run {
                    appendDebug("✅ Success! Channel found:")
                    appendDebug("  - Name: \(channel.name)")
                    appendDebug("  - ID: \(channel.id)")
                    appendDebug("  - Handle: \(channel.handle ?? "N/A")")
                    appendDebug("  - Subscribers: \(channel.subscriberCount ?? "N/A")")
                    isLoading = false
                }
                
                // Test fetching videos
                appendDebug("🔄 Testing video fetch...")
                let videos = try await YouTubeAPIService.shared.getChannelVideos(
                    channelId: channel.id,
                    lookbackDays: 7,
                    maxResults: 5
                )
                
                await MainActor.run {
                    appendDebug("✅ Videos fetched: \(videos.count)")
                    for (index, video) in videos.prefix(3).enumerated() {
                        appendDebug("  \(index + 1). \(video.title)")
                    }
                }
                
            } catch {
                await MainActor.run {
                    appendDebug("❌ Error: \(error.localizedDescription)")
                    if let apiError = error as? YouTubeAPIError {
                        appendDebug("   Type: \(apiError)")
                    }
                    isLoading = false
                }
            }
        }
    }
    
    private func appendDebug(_ message: String) {
        let timestamp = DateFormatter.debugFormatter.string(from: Date())
        debugOutput += "[\(timestamp)] \(message)\n"
    }
}

extension DateFormatter {
    static let debugFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

#Preview {
    DebugView()
}
