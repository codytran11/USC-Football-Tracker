import SwiftUI

struct SeasonView: View {
    struct RosterMember {
        let role: String
        let player: Player
    }

    let season: Season
    let roster: [RosterMember]

    init(season: Season, players: [String: Player]) {
        self.season = season
        self.roster = season.roster.map { member in
            if let player = players[member.id] {
                return RosterMember(role: member.role, player: player)
            } else {
                fatalError("Missing \(member.id)")
            }
        }.sorted {
            let leftRank = positionRank($0.player.position)
            let rightRank = positionRank($1.player.position)

            if leftRank != rightRank {
                return leftRank < rightRank
            } else {
                return $0.player.name < $1.player.name
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                sectionTitle("Games")
                VStack(spacing: 12) {
                    ForEach(season.games) { game in
                        GameRow(game: game)
                    }
                }
                if let coach = season.headCoach {
                    sectionTitle("Head Coach")

                    HStack {
                        Text(coach.name)
                            .font(.headline)

                        Spacer()

                        Text(coach.role)
                            .font(.subheadline)
                            .foregroundStyle(.uscCardinal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
                    )
                }

                sectionTitle("Roster")
                VStack(spacing: 12) {
                    ForEach(roster, id: \.player.id) { member in
                        PlayerRosterRow(member: member)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("\(season.id) Season")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(season.id)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.uscCardinal)

            HStack {
                Text("Record")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(season.record)
                    .font(.headline.bold())
                    .foregroundStyle(.uscCardinal)
            }

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.uscCardinal.opacity(0.25), lineWidth: 1)
        )
        .shadow(radius: 4, y: 2)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .foregroundStyle(.uscCardinal)
            .padding(.top, 4)
    }
}

struct GameRow: View {
    let game: Season.GameEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.opponent)
                    .font(.headline)

                if let date = game.gameDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(game.formattedScore)
                .font(.headline.bold())
                .foregroundStyle(.uscCardinal)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
        )
    }
}


struct PlayerRosterRow: View {
    let member: SeasonView.RosterMember

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.player.name)
                    .font(.headline)

                Text(member.role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(member.player.position), \(member.player.grade)")
                .font(.subheadline)
                .foregroundStyle(.uscCardinal)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
        )
    }
}

private func positionRank(_ position: String) -> Int {
    switch position.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
    case "QB": return 0
    case "RB", "FB": return 1
    case "WR": return 2
    case "TE": return 3
    case "OL", "OT", "OG", "C": return 4
    case "DL", "DE", "DT": return 5
    case "LB": return 6
    case "CB": return 7
    case "S", "SS", "FS": return 8
    case "K": return 9
    case "P": return 10
    default: return 99
    }
}
