import Foundation

struct Puzzle: Codable, Identifiable, Sendable {
    let id: String
    /// FEN of the position BEFORE the opponent's setup move. Lichess puzzles
    /// describe the position one ply earlier than the player's first move so
    /// the setup looks natural to the user (the opponent makes a tactical
    /// blunder; the player exploits it). When `setupMove` is non-nil the
    /// catalog applies it before the puzzle starts.
    let fen: String
    /// Optional opponent move (UCI) applied to `fen` to reach the actual
    /// puzzle start position. Nil for hand-written puzzles whose `fen` is
    /// already the player-to-move position.
    let setupMove: String?
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
