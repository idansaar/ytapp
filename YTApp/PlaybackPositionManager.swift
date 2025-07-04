import Foundation

class PlaybackPositionManager: ObservableObject {
    private let positionsKey = "videoPlaybackPositions"
    private var positions: [String: PlaybackPosition] = [:]
    
    struct PlaybackPosition: Codable {
        let videoID: String
        let position: Double // Position in seconds
        let duration: Double // Total duration in seconds
        let lastUpdated: Date
        
        var isPartiallyWatched: Bool {
            return position > 5 && position < (duration - 5) // At least 5 seconds in, not near the end
        }
        
        var watchProgress: Double {
            guard duration > 0 else { return 0 }
            return min(position / duration, 1.0)
        }
        
        var formattedPosition: String {
            return PlaybackPosition.formatTime(position)
        }
        
        var formattedDuration: String {
            return PlaybackPosition.formatTime(duration)
        }
        
        static func formatTime(_ seconds: Double) -> String {
            let totalSeconds = Int(seconds)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let secs = totalSeconds % 60
            
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, secs)
            } else {
                return String(format: "%d:%02d", minutes, secs)
            }
        }
    }
    
    init() {
        loadPositions()
    }
    
    // MARK: - Public Methods
    
    func savePosition(videoID: String, position: Double, duration: Double) {
        let previousPosition = positions[videoID]?.position ?? 0
        let isNewVideo = positions[videoID] == nil
        
        print("💾 [DEBUG] Saving playback position for \(videoID):")
        print("   📍 Position: \(String(format: "%.1f", position))s -> \(PlaybackPosition.formatTime(position))")
        print("   📏 Duration: \(String(format: "%.1f", duration))s -> \(PlaybackPosition.formatTime(duration))")
        print("   📊 Progress: \(String(format: "%.1f", (position/duration)*100))%")
        if !isNewVideo {
            print("   🔄 Previous: \(String(format: "%.1f", previousPosition))s (Δ: +\(String(format: "%.1f", position - previousPosition))s)")
        } else {
            print("   🆕 First position save for this video")
        }
        
        let playbackPosition = PlaybackPosition(
            videoID: videoID,
            position: position,
            duration: duration,
            lastUpdated: Date()
        )
        
        positions[videoID] = playbackPosition
        savePositions()
    }
    
    func getPosition(for videoID: String) -> PlaybackPosition? {
        let position = positions[videoID]
        if let pos = position {
            print("📖 [DEBUG] Retrieved saved position for \(videoID): \(pos.formattedPosition) (\(String(format: "%.1f", pos.position))s)")
        } else {
            print("📖 [DEBUG] No saved position found for \(videoID)")
        }
        return position
    }
    
    func clearPosition(for videoID: String) {
        print("🗑️ Clearing playback position for \(videoID)")
        positions.removeValue(forKey: videoID)
        savePositions()
    }
    
    func hasPosition(for videoID: String) -> Bool {
        return positions[videoID] != nil
    }
    
    func isPartiallyWatched(_ videoID: String) -> Bool {
        return positions[videoID]?.isPartiallyWatched ?? false
    }
    
    func getWatchProgress(for videoID: String) -> Double {
        return positions[videoID]?.watchProgress ?? 0
    }
    
    // MARK: - Persistence
    
    private func savePositions() {
        do {
            let data = try JSONEncoder().encode(positions)
            UserDefaults.standard.set(data, forKey: positionsKey)
            print("💾 Saved \(positions.count) playback positions")
        } catch {
            print("❌ Error saving playback positions: \(error)")
        }
    }
    
    private func loadPositions() {
        guard let data = UserDefaults.standard.data(forKey: positionsKey) else {
            print("📂 No saved playback positions found")
            return
        }
        
        do {
            positions = try JSONDecoder().decode([String: PlaybackPosition].self, from: data)
            print("📂 Loaded \(positions.count) playback positions")
        } catch {
            print("❌ Error loading playback positions: \(error)")
            positions = [:]
        }
    }
    
    // MARK: - Cleanup
    
    func cleanupOldPositions(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let oldCount = positions.count
        
        positions = positions.filter { $0.value.lastUpdated > cutoffDate }
        
        if positions.count != oldCount {
            savePositions()
            print("🧹 Cleaned up \(oldCount - positions.count) old playback positions")
        }
    }
}
