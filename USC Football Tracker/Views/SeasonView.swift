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
        }
    }

    private var groupedRoster: [(title: String, players: [RosterMember])] {
        let grouped = Dictionary(grouping: roster) { member in
            positionGroup(member.player.position)
        }

        let order = [
            "Quarterbacks",
            "Running Backs",
            "Wide Receivers",
            "Tight Ends",
            "Offensive Line",
            "Defensive Line",
            "Linebackers",
            "Defensive Backs",
            "Special Teams",
            "Other"
        ]

        return order.compactMap { groupName in
            guard let players = grouped[groupName], !players.isEmpty else { return nil }
            return (title: groupName, players: players)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                SeasonSummaryCard(season: season)

                sectionTitle("Games")
                VStack(spacing: 12) {
                    ForEach(season.games) { game in
                        GameRow(game: game)
                    }
                }

                sectionTitle("Roster")
                if roster.isEmpty {
                    Text("No roster data available")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(groupedRoster, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    Text(group.title)
                                        .font(.title3.bold())
                                        .foregroundStyle(.uscCardinal)

                                    Spacer()

                                    Text("\(group.players.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(.gray.opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                VStack(spacing: 12) {
                                    ForEach(group.players, id: \.player.id) { member in
                                        PlayerRosterRow(member: member)
                                    }
                                }
                            }
                        }
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
            Text("\(season.id) USC Trojans")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.uscCardinal)

            Text(season.record)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.uscCardinal)

            Text("Season Overview")
                .font(.headline)
                .foregroundStyle(.secondary)
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

    private func positionGroup(_ position: String) -> String {
        switch position.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "QB":
            return "Quarterbacks"
        case "RB", "FB":
            return "Running Backs"
        case "WR":
            return "Wide Receivers"
        case "TE":
            return "Tight Ends"
        case "OL", "OT", "OG", "C":
            return "Offensive Line"
        case "DL", "DE", "DT":
            return "Defensive Line"
        case "LB", "ILB", "OLB":
            return "Linebackers"
        case "CB", "S", "SS", "FS", "DB":
            return "Defensive Backs"
        case "K", "P", "LS", "PK":
            return "Special Teams"
        default:
            return "Other"
        }
    }
}

private struct SeasonSummaryCard: View {
    let season: Season

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            if let rank = season.finalAPRank {
                SummaryStatCard(
                    icon: "star.fill",
                    title: "AP Rank",
                    value: "#\(rank)"
                )
            }

            if let coach = season.headCoach {
                SummaryStatCard(
                    icon: "person.fill",
                    title: "Head Coach",
                    value: coach.name
                )
            }

            if let conference = season.conference {
                SummaryStatCard(
                    icon: "sportscourt.fill",
                    title: "Conference",
                    value: conference
                )
            }

            if let conferenceRecord = season.conferenceRecord {
                SummaryStatCard(
                    icon: "chart.bar.fill",
                    title: "Conf. Record",
                    value: conferenceRecord
                )
            }

            if let bowlGame = season.bowlGame {
                SummaryStatCard(
                    icon: "trophy.fill",
                    title: "Bowl",
                    value: bowlGame,
                    detail: season.bowlResult
                )
            }
        }
    }
}

private struct SummaryStatCard: View {
    let icon: String
    let title: String
    let value: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.uscCardinal)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
        )
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

                if member.player.jerseyNumber > 0 {
                    Text("#\(member.player.jerseyNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(member.player.position)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.uscCardinal)

                if !member.player.grade.isEmpty {
                    Text(member.player.grade)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
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
