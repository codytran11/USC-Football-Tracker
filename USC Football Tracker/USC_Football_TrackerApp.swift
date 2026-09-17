import SwiftUI

@main
struct USC_Football_TrackerApp: App {

    @State private var hasEnteredApp = false

    var body: some Scene {
        WindowGroup {
            if hasEnteredApp {
                TabView {
                    ContentView()
                        .tabItem {
                            Label("Seasons", systemImage: "calendar")
                        }

                    PredictorView()
                        .tabItem {
                            Label("Predictor", systemImage: "chart.line.uptrend.xyaxis")
                        }

                    AccoladesView()
                        .tabItem {
                            Label("Accolades", systemImage: "trophy.fill")
                        }

                    AboutView()
                        .tabItem {
                            Label("About", systemImage: "info.circle")
                        }
                }
                .preferredColorScheme(.light)

            } else {
                LandingView {
                    hasEnteredApp = true
                }
                .preferredColorScheme(.light)
            }
        }
    }
}

#Preview {
    USC_Football_TrackerApp_Preview()
}

private struct USC_Football_TrackerApp_Preview: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Seasons", systemImage: "calendar")
                }

            PredictorView()
                .tabItem {
                    Label("Predictor", systemImage: "chart.line.uptrend.xyaxis")
                }

            AccoladesView()
                .tabItem {
                    Label("Accolades", systemImage: "trophy.fill")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .preferredColorScheme(.light)
    }
}
