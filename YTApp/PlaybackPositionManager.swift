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
            return position > 30 && position < (duration - 30) // At least 30 seconds in, not near the end
        }
        
        var watchProgress: Double {
            guard duration > 0 else { return 0 }
            return min(position / duration, 1.0)
        }
        
        var formattedPosition: String {
            return formatTime(position)
        }
        
        var formattedDuration: String {
            return formatTime(duration)
        }
        
        private func formatTime(_ seconds: Double) -> String {
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
        print("💾 Saving playback position for \(videoID): \(position)/\(duration) seconds")
        
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
        return positions[videoID]
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
