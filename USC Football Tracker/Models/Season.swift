import Foundation
struct Season: Codable, Identifiable {
    struct Roster: Codable {
        let id: String
        let role: String
    }
    struct Coach: Codable, Identifiable {
          let id: String
          let name: String
          let role: String
      }
    struct GameEntry: Codable, Identifiable {
        let id: Int
        let opponent: String
        let gameDate: Date?
        let home: Bool
        let uscScore: Int?
        let oppScore: Int?
        enum Outcome: String, Codable {
            case win = "W"
            case lost = "L"
            case upcoming = "N/A"
        }
        let outcome : Outcome

        var formattedScore: String {
            if let uscScore, let oppScore {
                return "\(uscScore)-\(oppScore)"
            } else {
                return "Upcoming"
            }
        }
    }
    let id: String
    let games: [GameEntry]
    let roster: [Roster]
    let headCoach: Coach?
    let finalAPRank: Int?
    let bowlGame: String?
    let bowlResult: String?
    let conference: String?
    let conferenceRecord: String?
    let nationalChampion: Bool?
    let conferenceChampion: Bool?

    var record: String {
        let wins = games.filter { $0.outcome == .win }.count
        let losses = games.filter { $0.outcome == .lost }.count
        return "\(wins)-\(losses)"
    }
}
