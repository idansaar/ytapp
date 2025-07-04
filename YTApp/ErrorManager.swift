import SwiftUI
import Foundation

// MARK: - App Error Types
enum AppError: LocalizedError, Identifiable {
    case networkError(String)
    case videoLoadError(String)
    case dataError(String)
    case clipboardError(String)
    case channelError(String)
    case playbackError(String)
    case unknownError(String)
    
    var id: String {
        switch self {
        case .networkError(let message): return "network_\(message.hashValue)"
        case .videoLoadError(let message): return "video_\(message.hashValue)"
        case .dataError(let message): return "data_\(message.hashValue)"
        case .clipboardError(let message): return "clipboard_\(message.hashValue)"
        case .channelError(let message): return "channel_\(message.hashValue)"
        case .playbackError(let message): return "playback_\(message.hashValue)"
        case .unknownError(let message): return "unknown_\(message.hashValue)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .videoLoadError(let message):
            return "Video Loading Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .clipboardError(let message):
            return "Clipboard Error: \(message)"
        case .channelError(let message):
            return "Channel Error: \(message)"
        case .playbackError(let message):
            return "Playback Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .videoLoadError:
            return "The video may be unavailable. Try a different video or check the URL."
        case .dataError:
            return "There was a problem with your data. Try restarting the app."
        case .clipboardError:
            return "Please copy a valid YouTube URL to your clipboard."
        case .channelError:
            return "Unable to load channel information. Please try again later."
        case .playbackError:
            return "There was a problem playing the video. Please try again."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var icon: String {
        switch self {
        case .networkError:
            return "wifi.exclamationmark"
        case .videoLoadError:
            return "play.slash"
        case .dataError:
            return "externaldrive.badge.exclamationmark"
        case .clipboardError:
            return "clipboard.fill"
        case .channelError:
            return "tv.badge.wifi.exclamationmark"
        case .playbackError:
            return "speaker.slash"
        case .unknownError:
            return "exclamationmark.triangle"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError, .videoLoadError, .channelError, .playbackError:
            return .warning
        case .dataError, .unknownError:
            return .error
        case .clipboardError:
            return .info
        }
    }
}

enum ErrorSeverity {
    case info
    case warning
    case error
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Error Manager
class ErrorManager: ObservableObject {
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorLogEntry] = []
    
    private let maxHistoryCount = 50
    
    struct ErrorLogEntry: Identifiable {
        let id = UUID()
        let error: AppError
        let timestamp: Date
        let context: String?
        
        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter.string(from: timestamp)
        }
    }
    
    func reportError(_ error: AppError, context: String? = nil) {
        print("🚨 [ERROR] \(error.errorDescription ?? "Unknown error")")
        if let context = context {
            print("📍 [CONTEXT] \(context)")
        }
        
        DispatchQueue.main.async {
            self.currentError = error
            self.addToHistory(error, context: context)
        }
    }
    
    func clearCurrentError() {
        DispatchQueue.main.async {
            self.currentError = nil
        }
    }
    
    private func addToHistory(_ error: AppError, context: String?) {
        let entry = ErrorLogEntry(error: error, timestamp: Date(), context: context)
        errorHistory.insert(entry, at: 0)
        
        // Keep only the most recent errors
        if errorHistory.count > maxHistoryCount {
            errorHistory = Array(errorHistory.prefix(maxHistoryCount))
        }
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    // Convenience methods for common errors
    func reportNetworkError(_ message: String, context: String? = nil) {
        reportError(.networkError(message), context: context)
    }
    
    func reportVideoLoadError(_ message: String, context: String? = nil) {
        reportError(.videoLoadError(message), context: context)
    }
    
    func reportDataError(_ message: String, context: String? = nil) {
        reportError(.dataError(message), context: context)
    }
    
    func reportClipboardError(_ message: String, context: String? = nil) {
        reportError(.clipboardError(message), context: context)
    }
    
    func reportChannelError(_ message: String, context: String? = nil) {
        reportError(.channelError(message), context: context)
    }
    
    func reportPlaybackError(_ message: String, context: String? = nil) {
        reportError(.playbackError(message), context: context)
    }
}

// MARK: - Error Alert View
struct ErrorAlertView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: error.icon)
                .font(.system(size: 50))
                .foregroundColor(error.severity.color)
            
            // Error Title
            Text(error.errorDescription ?? "Error")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                if let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Error Toast View
struct ErrorToastView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.icon)
                .foregroundColor(error.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "Error")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            isVisible = true
            
            // Auto-dismiss after 5 seconds for info/warning errors
            if error.severity != .error {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Error History View
struct ErrorHistoryView: View {
    @ObservedObject var errorManager: ErrorManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if errorManager.errorHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("No Errors")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Your app is running smoothly!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(errorManager.errorHistory) { entry in
                        ErrorHistoryRowView(entry: entry)
                    }
                }
            }
            .navigationTitle("Error History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                if !errorManager.errorHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            errorManager.clearErrorHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct ErrorHistoryRowView: View {
    let entry: ErrorManager.ErrorLogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.error.icon)
                .foregroundColor(entry.error.severity.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.error.errorDescription ?? "Unknown Error")
                    .font(.body)
                    .fontWeight(.medium)
                
                if let context = entry.context {
                    Text("Context: \(context)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ErrorAlertView(
        error: .networkError("Unable to connect to the internet"),
        onDismiss: {},
        onRetry: {}
    )
}
