import SwiftUI

struct ComingSoonView: View {
    let title: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.uscCardinal)

                Text("Coming Soon")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(title)
        }
    }
}

struct PredictorView: View {
    var body: some View {
        ComingSoonView(title: "2025-2026 Season Predictor")
    }
}

struct LegendsView: View {
    var body: some View {
        ComingSoonView(title: "USC Legends")
    }
}

struct TrophyRoomView: View {
    var body: some View {
        ComingSoonView(title: "USC Accolades")
    }
}

struct AboutFootballView: View {
    var body: some View {
        ComingSoonView(title: "About USC Football")
    }
}
