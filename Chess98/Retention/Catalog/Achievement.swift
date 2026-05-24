import Foundation

struct Achievement: Identifiable, Sendable {
    enum Tier: Sendable {
        case bronze, silver, gold

        /// Star glyphs used in the Win98-styled achievements list.
        var stars: String {
            switch self {
            case .bronze: "★"
            case .silver: "★★"
            case .gold:   "★★★"
            }
        }
    }

    let id: String                  // stable, ASCII snake_case (persisted)
    let title: String
    let description: String
    let tier: Tier
    let predicate: @Sendable (AchievementContext) -> Bool
}

/// Inputs passed to an achievement predicate. The evaluator runs after stats
/// have been updated for the most recent event, so reading `stats` reflects
/// the post-event totals.
struct AchievementContext {
    let stats: PlayerStats
    let lastResult: GameResult?
}
