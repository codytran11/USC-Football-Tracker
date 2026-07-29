import SwiftUI

struct ContentView: View {
    let seasons: [Season] = {
        let decoded: [Season] = Bundle.main.decode("seasons.json")
        return decoded.sorted { Int($0.id) ?? 0 > Int($1.id) ?? 0 }
    }()
    let players: [String: Player] = Bundle.main.decode("players.json")
    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(seasons) { season in
                        NavigationLink {
                            SeasonView(season: season, players: players)
                        } label: {
                            SeasonGridCard(season: season)
                        }
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("USC Football Tracker")
        }
    }
}

struct SeasonGridCard: View {
    let season: Season
    var body: some View {
        VStack {
            Text("\(season.id)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.uscCardinal)

            VStack(spacing: 4) {
                Text(season.record)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(.uscCardinal)
        }
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.uscCardinal)
        )
    }
}

#Preview {
    ContentView()
}
