import SwiftUI

@main
struct YTAppApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(persistenceController)
        }
    }
}
