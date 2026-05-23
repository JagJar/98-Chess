import Foundation
import SwiftData

@Model
final class SavedGame {
    // Whitespace-separated UCI move list (e.g. "e2e4 e7e5 g1f3").
    // Replaying these from the standard starting position reproduces
    // the full game including repetition counters and undo history.
    var uciMoves: String

    var updatedAt: Date

    init(uciMoves: String = "", updatedAt: Date = .now) {
        self.uciMoves = uciMoves
        self.updatedAt = updatedAt
    }
}
