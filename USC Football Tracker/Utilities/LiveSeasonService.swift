import Foundation

struct LiveSeasonService {

    private let url = URL(
        string: "https://usc-football-api.vercel.app/api/usc-2026"
    )!

    func fetchGames() async throws -> [Season.GameEntry] {

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        decoder.dateDecodingStrategy = .formatted(formatter)

        return try decoder.decode(
            [Season.GameEntry].self,
            from: data
        )
    }
}
