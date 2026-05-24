import Foundation

enum PuzzleCatalog {
    static let all: [Puzzle] = loadFromBundle()

    /// Picks today's puzzle deterministically by day-of-era, so the same
    /// calendar day always shows the same puzzle even across relaunches.
    static func today(now: Date = .now, calendar: Calendar = .current) -> Puzzle? {
        guard !all.isEmpty else { return nil }
        let dayIndex = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        return all[dayIndex % all.count]
    }

    private static func loadFromBundle() -> [Puzzle] {
        guard let url = Bundle.main.url(forResource: "Puzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([Puzzle].self, from: data)) ?? []
    }
}
