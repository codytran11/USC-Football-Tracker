import SwiftUI

struct ContentView: View {
    let seasons: [Season] = {
        let decoded: [Season] = Bundle.main.decode("seasons.json")
        return decoded.sorted { (Int($0.id) ?? 0) > (Int($1.id) ?? 0) }
    }()

    let players: [String: Player] = Bundle.main.decode("players.json")

    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]

    private let championshipSeasons: Set<String> = [
        "1928",
        "1931",
        "1932",
        "1939",
        "1962",
        "1967",
        "1972",
        "1974",
        "1978",
        "2003",
        "2004"
    ]

    private func isNationalChampion(_ season: Season) -> Bool {
        season.nationalChampion ?? championshipSeasons.contains(season.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USC Seasons")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.uscCardinal)

                        Text("Browse every USC football season from 1888 to the present, including each team's record, roster, and game results." )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("*Some early USC seasons may have limited roster, coaching, or game information due to historical data availability.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)

                            Text("National championship seasons are marked with a trophy.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(seasons) { season in
                            NavigationLink {
                                SeasonView(season: season, players: players)
                            } label: {
                                SeasonTile(
                                    season: season,
                                    isChampion: isNationalChampion(season)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Seasons")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SeasonTile: View {
    let season: Season
    let isChampion: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Text(season.id)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.uscCardinal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("Season")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 92)
                .padding(.horizontal, 10)
                .background(.white)

                if isChampion {
                    Image(systemName: "trophy.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.yellow)
                        .padding(8)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(.uscCardinal)

                Text(season.record)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(height: 38)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.uscCardinal.opacity(0.18), lineWidth: 1)
        )
        .shadow(radius: 2, y: 1)
    }
}

#Preview {
    ContentView()
}
