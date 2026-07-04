import SwiftUI
import SwiftData

@main
struct SparkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        // All data lives in a local SwiftData store on this device.
        // Nothing is sent anywhere unless the user explicitly exports.
        .modelContainer(for: [Idea.self, TasteProfile.self])
    }
}
