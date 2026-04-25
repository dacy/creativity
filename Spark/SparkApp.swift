import SwiftUI

@main
struct SparkApp: App {
    @StateObject private var session = IdeaSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}
