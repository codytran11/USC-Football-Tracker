import SwiftUI

struct LandingView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    Spacer(minLength: 40)

                    // App icon / logo
                    Image("AppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)

                    VStack(spacing: 10) {
                        Text("USC Football Tracker")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.uscCardinal)
                            .multilineTextAlignment(.center)

                        Text("The App for all USC Football Fans.")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 14) {
                        LandingFeature(
                            icon: "clock.arrow.circlepath",
                            title: "Explore Data",
                            description: "Browse seasons, game results, rosters, and coaches."
                        )

                        LandingFeature(
                            icon: "trophy.fill",
                            title: "USC Accolades",
                            description: "Explore championships, Heisman winners, records, and more."
                        )

                        LandingFeature(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Season Predictor",
                            description: "View machine-learning-powered predictions for the upcoming season."
                        )
                    }
                    .padding(.horizontal, 4)

                    Button {
                        onContinue()
                    } label: {
                        HStack {
                            Text("Explore USC Football")
                                .font(.headline)

                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.uscCardinal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 8)

                    Text("Built independently as a student project.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.light)
    }
}

private struct LandingFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.uscCardinal)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.uscCardinal.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    LandingView {
    }
}
