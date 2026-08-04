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

    // Official USC 2026 schedule (regular season).
    private let demoGames: [DemoGame] = [
        DemoGame(gameIndex: 1, opponent: "San José State", isHome: true, conferenceGame: false, uscAPRank: 0, oppAPRank: 0, hype: 6),
        DemoGame(gameIndex: 2, opponent: "Fresno State", isHome: true, conferenceGame: false, uscAPRank: 0, oppAPRank: 0, hype: 3),
        DemoGame(gameIndex: 3, opponent: "Louisiana", isHome: true, conferenceGame: false, uscAPRank: 0, oppAPRank: 0, hype: 4),
        DemoGame(gameIndex: 4, opponent: "Rutgers", isHome: false, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 4),
        DemoGame(gameIndex: 5, opponent: "Oregon", isHome: true, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 10),
        DemoGame(gameIndex: 6, opponent: "Washington", isHome: true, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 6),
        DemoGame(gameIndex: 7, opponent: "Penn State", isHome: false, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 7),
        DemoGame(gameIndex: 8, opponent: "Wisconsin", isHome: false, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 5),
        DemoGame(gameIndex: 9, opponent: "Ohio State", isHome: true, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 10),
        DemoGame(gameIndex: 10, opponent: "Indiana", isHome: false, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 9),
        DemoGame(gameIndex: 11, opponent: "Maryland", isHome: true, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 5),
        DemoGame(gameIndex: 12, opponent: "UCLA", isHome: false, conferenceGame: true, uscAPRank: 0, oppAPRank: 0, hype: 9)
    ]

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

                        Text("Predictions are generated using a machine learning model trained on USC Football games from the 2021–2025 seasons.")
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
            let model = try USC_Season_Predictor_2(configuration: MLModelConfiguration())

            var items: [GamePrediction] = []
            var totalWinProbability = 0.0
            var totalCertainty = 0.0

            for game in demoGames {
                let prediction = try model.prediction(
                    seasonYear: seasonYear,
                    gameIndex: Int64(game.gameIndex),
                    home: game.isHome ? 1 : 0,
                    conferenceGame: game.conferenceGame ? 1 : 0,
                    uscAPRank: game.uscAPRank,
                    oppAPRank: game.oppAPRank
                )

                let winProbability = prediction.resultProbability[1] ?? 0.0
                totalWinProbability += winProbability
                totalCertainty += max(winProbability, 1.0 - winProbability)

                items.append(
                    GamePrediction(
                        opponent: game.opponent,
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
}

private struct DemoGame {
    let gameIndex: Int
    let opponent: String
    let isHome: Bool
    let conferenceGame: Bool
    let uscAPRank: Int64
    let oppAPRank: Int64
    let hype: Int
}

struct GamePrediction: Identifiable {
    let id = UUID()
    let opponent: String
    let isHome: Bool
    let conferenceGame: Bool
    let winProbability: Double
    let hype: Int
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.opponent)
                        .font(.headline)

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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
        )
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
