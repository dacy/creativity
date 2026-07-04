import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SwipeView()
                .tabItem { Label("Swipe", systemImage: "hand.draw") }
            LikedView()
                .tabItem { Label("Liked", systemImage: "heart.fill") }
            ProfileView()
                .tabItem { Label("Your taste", systemImage: "sparkles") }
        }
        .tint(Color(red: 0.49, green: 0.42, blue: 0.96))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Idea.self, TasteProfile.self], inMemory: true)
}
