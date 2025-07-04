import UIKit
import SwiftUI

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Context-Specific Feedback
    func videoPlay() {
        mediumImpact()
    }
    
    func videoPause() {
        lightImpact()
    }
    
    func addToFavorites() {
        success()
    }
    
    func removeFromFavorites() {
        lightImpact()
    }
    
    func deleteItem() {
        mediumImpact()
    }
    
    func buttonTap() {
        lightImpact()
    }
    
    func tabSwitch() {
        selection()
    }
    
    func pullToRefresh() {
        lightImpact()
    }
    
    func errorOccurred() {
        error()
    }
    
    func settingsChange() {
        lightImpact()
    }
    
    func dataCleared() {
        warning()
    }
    
    func channelAdded() {
        success()
    }
    
    func clipboardDetected() {
        lightImpact()
    }
}

// MARK: - SwiftUI View Extension for Haptic Feedback
extension View {
    func hapticFeedback(_ type: HapticFeedbackType) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            case .selection:
                HapticManager.shared.selection()
            }
        }
    }
    
    func onButtonTap(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.buttonTap()
            action()
        }
    }
}

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}
