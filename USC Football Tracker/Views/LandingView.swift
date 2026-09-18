import SwiftUI

struct LandingView: View {

    let onContinue: () -> Void

    var body: some View {
        ZStack {

            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.0, blue: 0.0),
                    Color(red: 0.55, green: 0.0, blue: 0.0),
                    Color(red: 0.20, green: 0.0, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {

                    Spacer(minLength: 45)

                    // App logo
                    Image("LandingLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 125, height: 125)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 28)
                        )
                        .shadow(
                            color: .black.opacity(0.25),
                            radius: 10,
                            y: 5
                        )

                    VStack(spacing: 8) {

                        Text("USC Football")
                            .font(
                                .system(
                                    size: 34,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)

                        Text("Tracker")
                            .font(
                                .system(
                                    size: 34,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.uscGold)

                        Text("Your USC Football Companion")
                            .font(.title3)
                            .foregroundStyle(
                                Color.white.opacity(0.8)
                            )
                            .multilineTextAlignment(.center)
                    }

                    
                    Text(
                        "Go Through USC football history, follow the current team, and discover what the numbers say about the season."
                    )
                    .font(.body)
                    .foregroundStyle(
                        Color.white.opacity(0.8)
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

               
                    VStack(spacing: 10) {

                        LandingHighlight(
                            icon: "clock.arrow.circlepath",
                            text: "100+ years of USC football history"
                        )

                        LandingHighlight(
                            icon: "person.3.fill",
                            text: "Current rosters, coaches, and schedules"
                        )

                        LandingHighlight(
                            icon: "chart.line.uptrend.xyaxis",
                            text: "Machine-learning season predictions"
                        )
                    }

                    // Main button
                    Button {
                        onContinue()
                    } label: {

                        HStack(spacing: 10) {

                            Text("Explore USC Football")
                                .font(
                                    .headline.weight(.bold)
                                )

                            Image(
                                systemName: "arrow.right"
                            )
                            .font(
                                .headline.weight(.bold)
                            )
                        }
                        .foregroundStyle(
                            Color(
                                red: 0.28,
                                green: 0.0,
                                blue: 0.0
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.uscGold)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.2),
                            radius: 8,
                            y: 4
                        )
                    }
                    .padding(.top, 4)

                 
                    VStack(spacing: 5) {

                        Text("FIGHT ON!")
                            .font(
                                .caption.weight(.bold)
                            )
                            .tracking(1.2)
                            .foregroundStyle(.uscGold)

                       
                        .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct LandingHighlight: View {

    let icon: String
    let text: String

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.uscGold)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.15)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 12
            )
            .stroke(
                Color.uscGold.opacity(0.18),
                lineWidth: 1
            )
        )
    }
}

#Preview {
    LandingView {
    }
}
