import SwiftUI

@main
struct GaiaFactoryApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("GAIA APP FACTORY")
                        .font(.title.bold())
                        .foregroundStyle(.cyan)
                    Text("APPLE GATE: ONLINE")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.green)
                }
            }
        }
    }
}
