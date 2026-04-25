import SwiftUI

enum Theme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.07, blue: 0.12),
            Color(red: 0.12, green: 0.08, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let card = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.10)
    static let primaryAccent = Color(red: 1.0, green: 0.62, blue: 0.36)
    static let secondaryAccent = Color(red: 0.55, green: 0.78, blue: 1.0)
}

struct CardBackground: ViewModifier {
    var selected: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selected ? Theme.primaryAccent.opacity(0.18) : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(selected ? Theme.primaryAccent : Theme.cardStroke, lineWidth: selected ? 2 : 1)
            )
    }
}

extension View {
    func cardStyle(selected: Bool = false) -> some View {
        modifier(CardBackground(selected: selected))
    }
}
