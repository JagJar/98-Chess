import Foundation

struct Puzzle: Codable, Identifiable, Sendable {
    let id: String
    let fen: String
    /// Alternating UCI moves starting with the player's first move
    /// (player at even indices, forced opponent reply at odd indices).
    /// Mate-in-1 puzzles have a single entry.
    let solution: [String]
    /// Optional list of acceptable alternative moves per ply index.
    /// `alternatives[i]` is a list of UCI strings; an empty array means
    /// only `solution[i]` is acceptable. Pad with empty arrays where unused.
    let alternatives: [[String]]?
    let title: String
    let hint: String?
}
