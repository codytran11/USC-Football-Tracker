import Foundation
import SwiftUI
import CoreML

struct PredictorView: View {
    @State private var projectedWins: Int?
    @State private var projectedLosses: Int?
    @State private var confidence: Double?
    @State private var gamePredictions: [GamePrediction] = []
    @State private var loadError: String?
    @State private var didLoadPredictions = false

    private let seasonYear: Int64 = 2026
    private let seasons: [Season] = Bundle.main.decode("seasons.json")

    private let demoGames: [DemoGame] = [
        DemoGame(gameIndex: 1, opponent: "San José State", date: "Aug 29", isHome: true, conferenceGame: false, hype: 6),
        DemoGame(gameIndex: 2, opponent: "Fresno State", date: "Sep 5", isHome: true, conferenceGame: false, hype: 3),
        DemoGame(gameIndex: 3, opponent: "Louisiana", date: "Sep 12", isHome: true, conferenceGame: false, hype: 4),
        DemoGame(gameIndex: 4, opponent: "Rutgers", date: "Sep 19", isHome: false, conferenceGame: true, hype: 4),
        DemoGame(gameIndex: 5, opponent: "Oregon", date: "Sep 26", isHome: true, conferenceGame: true, hype: 10),
        DemoGame(gameIndex: 6, opponent: "Washington", date: "Oct 3", isHome: true, conferenceGame: true, hype: 6),
        DemoGame(gameIndex: 7, opponent: "Penn State", date: "Oct 10", isHome: false, conferenceGame: true, hype: 7),
        DemoGame(gameIndex: 8, opponent: "Wisconsin", date: "Oct 24", isHome: false, conferenceGame: true, hype: 5),
        DemoGame(gameIndex: 9, opponent: "Ohio State", date: "Oct 31", isHome: true, conferenceGame: true, hype: 10),
        DemoGame(gameIndex: 10, opponent: "Indiana", date: "Nov 14", isHome: false, conferenceGame: true, hype: 9),
        DemoGame(gameIndex: 11, opponent: "Maryland", date: "Nov 21", isHome: true, conferenceGame: true, hype: 5),
        DemoGame(gameIndex: 12, opponent: "UCLA", date: "Nov 28", isHome: false, conferenceGame: true, hype: 9)
    ]

    private var previousSeasonStats: (wins: Int64, losses: Int64, winPct: Double) {
        let previousYear = String(Int(seasonYear) - 1)
        guard let season = seasons.first(where: { $0.id == previousYear }) else {
            return (9, 4, 9.0 / 13.0)
        }

        let parts = season.record.split(separator: "-")
        if parts.count == 2,
           let wins = Int64(String(parts[0])),
           let losses = Int64(String(parts[1])) {
            let total = Double(wins + losses)
            return (wins, losses, total > 0 ? Double(wins) / total : 0.0)
        }

        return (9, 4, 9.0 / 13.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    HeroPredictionCard(
                        projectedWins: projectedWins,
                        projectedLosses: projectedLosses,
                        confidence: confidence
                    )

                    Text("Game Predictions")
                        .font(.title2.bold())
                        .foregroundStyle(.uscCardinal)

                    VStack(spacing: 10) {
                        Divider()

                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundStyle(.uscCardinal)

                        Text("Powered by Create ML + Core ML")
                            .font(.headline.weight(.semibold))

                        Text("Predictions are generated using a machine learning model trained on USC Football games from the 2005–2025 seasons.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)

                    if gamePredictions.isEmpty {
                        ProgressView("Loading predictions...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(gamePredictions) { game in
                                PredictionGameCard(game: game)
                            }
                        }
                    }

                    if let loadError {
                        Text(loadError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Predictor")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadPredictionsIfNeeded()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("USC Predictor")
                .font(.largeTitle.bold())
                .foregroundStyle(.uscCardinal)

            Text("Projected season outcome based on historical data and team trends.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Powered by Create ML + Core ML")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func loadPredictionsIfNeeded() {
        guard !didLoadPredictions else { return }
        didLoadPredictions = true
        loadPredictions()
    }

    private func loadPredictions() {
        do {
            let model = try USC_Season_Predictor_V2(configuration: MLModelConfiguration())
            let ratingsSnapshot: TeamRatingsSnapshot = Bundle.main.decode("team_ratings.json")

            var ratingsByCanonicalName: [String: Double] = [:]
            for (team, rating) in ratingsSnapshot.ratings {
                ratingsByCanonicalName[canonicalTeamName(team)] = rating
            }

            let uscCurrentRating = ratingsByCanonicalName[canonicalTeamName("USC")] ?? ratingsSnapshot.baseRating
            let previousStats = previousSeasonStats

            var items: [GamePrediction] = []
            var totalWinProbability = 0.0
            var totalCertainty = 0.0

            for game in demoGames {
                let oppElo = ratingsByCanonicalName[canonicalTeamName(game.opponent)] ?? ratingsSnapshot.baseRating

                let prediction = try model.prediction(
                    seasonYear: seasonYear,
                    gameIndex: Int64(game.gameIndex),
                    home: game.isHome ? 1 : 0,
                    conferenceGame: game.conferenceGame ? 1 : 0,
                    uscElo: uscCurrentRating,
                    oppElo: oppElo,
                    eloDiff: uscCurrentRating - oppElo,
                    uscPrevWins: previousStats.wins,
                    uscPrevLosses: previousStats.losses,
                    uscPrevWinPct: previousStats.winPct,
                    uscPrevRating: uscCurrentRating
                )

                let winProbability = prediction.resultProbability[1] ?? 0.0
                totalWinProbability += winProbability
                totalCertainty += max(winProbability, 1.0 - winProbability)

                items.append(
                    GamePrediction(
                        opponent: game.opponent,
                        date: game.date,
                        isHome: game.isHome,
                        conferenceGame: game.conferenceGame,
                        winProbability: winProbability,
                        hype: game.hype
                    )
                )
            }

            let wins = Int(round(totalWinProbability))
            let losses = max(0, items.count - wins)
            let avgConfidence = items.isEmpty ? 0 : totalCertainty / Double(items.count)

            projectedWins = wins
            projectedLosses = losses
            confidence = avgConfidence
            gamePredictions = items
            loadError = nil
        } catch {
            loadError = "Prediction failed: \(error.localizedDescription)"
        }
    }

    private func canonicalTeamName(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DemoGame {
    let gameIndex: Int
    let opponent: String
    let date: String
    let isHome: Bool
    let conferenceGame: Bool
    let hype: Int
}

struct GamePrediction: Identifiable {
    let id = UUID()
    let opponent: String
    let date: String
    let isHome: Bool
    let conferenceGame: Bool
    let winProbability: Double
    let hype: Int
}

private struct TeamRatingsSnapshot: Codable {
    let generatedAt: String
    let baseRating: Double
    let ratings: [String: Double]
}

struct HeroPredictionCard: View {
    let projectedWins: Int?
    let projectedLosses: Int?
    let confidence: Double?

    private var recordText: String {
        guard let projectedWins, let projectedLosses else { return "--" }
        return "\(projectedWins)–\(projectedLosses)"
    }

    private var winChanceText: String {
        guard let confidence else { return "--" }
        return "\(Int(confidence * 100))%"
    }

    private var confidenceLabel: String {
        guard let confidence else { return "Loading..." }
        if confidence >= 0.75 { return "Strong" }
        if confidence >= 0.60 { return "Moderate" }
        return "Uncertain"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Projected Record")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(recordText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.uscCardinal)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model Confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(winChanceText)
                        .font(.headline.bold())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Model Confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(confidenceLabel)
                        .font(.headline.bold())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
        )
        .shadow(radius: 3, y: 2)
    }
}

struct PredictionGameCard: View {
    let game: GamePrediction

    private var sideText: String {
        game.isHome ? "Home" : "Away"
    }

    private var labelText: String {
        let p = game.winProbability
        if p >= 0.70 { return "Favored" }
        if p >= 0.50 { return "Toss-up" }
        return "Underdog"
    }

    private var barColor: Color {
        let p = game.winProbability
        if p >= 0.70 { return .green }
        if p >= 0.50 { return .orange }
        return .red
    }

    private var isGameOfTheYear: Bool {
        game.opponent == "Ohio State"
    }

    private var isHalloweenGame: Bool {
        game.opponent == "Ohio State" && game.date.contains("Oct 31")
    }

    private var isRivalryGame: Bool {
        game.opponent == "UCLA"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.opponent)
                        .font(.headline)

                    Text(game.date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isGameOfTheYear {
                        Label("Game of the Year", systemImage: "trophy.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.uscCardinal)
                    }

                    if isHalloweenGame {
                        Label("Halloween Showdown", systemImage: "moon.stars.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    if isRivalryGame {
                        Label("Crosstown Rivalry", systemImage: "flag.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.uscCardinal)
                    }

                    HStack(spacing: 8) {
                        Text(sideText)
                        if game.conferenceGame {
                            Text("Conference")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(game.winProbability * 100))%")
                        .font(.headline.bold())
                        .foregroundStyle(.uscCardinal)

                    Text(labelText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HypeMeter(value: game.hype)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.gray.opacity(0.15))
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(geo.size.width * game.winProbability, 8))
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(isGameOfTheYear ? Color.orange.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isGameOfTheYear ? Color.orange.opacity(0.35) : .uscCardinal.opacity(0.15), lineWidth: 1)
        )
        .shadow(radius: 3, y: 2)
    }
}

private struct HypeMeter: View {
    let value: Int

    private var clampedValue: Int {
        min(max(value, 0), 10)
    }

    private var label: String {
        switch clampedValue {
        case 10:
            return "Game of the Year"
        case 9:
            return "Huge Matchup"
        case 7...8:
            return "Big Game"
        case 4...6:
            return "Worth Watching"
        default:
            return "Low-key"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Hype", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(clampedValue)/10")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.uscCardinal)
            }

            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { index in
                    Circle()
                        .fill(index <= clampedValue ? .gray : .gray.opacity(0.18))
                        .frame(width: 8, height: 8)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PredictorView()
}
