import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: IdeaSession

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Group {
                switch session.screen {
                case .welcome:
                    WelcomeView()
                case .decisions(let i):
                    if i < session.steps.count {
                        DecisionStepView(stepIndex: i)
                            .id(i)
                    } else {
                        ClarifyView()
                    }
                case .clarify:
                    ClarifyView()
                case .generating:
                    GeneratingView()
                case .idea:
                    IdeaView()
                case .researching:
                    ResearchingView()
                case .research:
                    ResearchView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.28), value: session.screen)
        }
    }
}
