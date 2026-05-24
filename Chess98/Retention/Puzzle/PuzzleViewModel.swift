import ChessKit
import Foundation
import Observation

@Observable
final class PuzzleViewModel {
    enum State: Equatable {
        case inProgress
        case wrongMove
        case solved
    }

    let puzzle: Puzzle
    let game: GameViewModel
    private(set) var state: State = .inProgress
    private(set) var moveIndex: Int = 0
    private(set) var attempts: Int = 0

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        let position = Position(fen: puzzle.fen) ?? .standard
        self.game = GameViewModel(startingPosition: position)
    }

    /// Validates the most recent move on `game` against the puzzle's expected
    /// sequence. Rolls back wrong moves. Applies any forced opponent reply
    /// automatically after a correct move. Returns the new state.
    @discardableResult
    func validateLastMove() -> State {
        guard state == .inProgress, let last = game.moves.last else { return state }
        attempts += 1
        let uci = EngineLANParser.convert(move: last)
        let expected = puzzle.solution[moveIndex]
        let alternatives = puzzle.alternatives?[safeIndex: moveIndex] ?? []
        guard uci == expected || alternatives.contains(uci) else {
            game.undo()
            state = .wrongMove
            return state
        }
        moveIndex += 1
        if moveIndex >= puzzle.solution.count {
            state = .solved
            return state
        }
        // Apply opponent's forced reply.
        _ = game.makeUCIMove(puzzle.solution[moveIndex])
        moveIndex += 1
        if moveIndex >= puzzle.solution.count {
            state = .solved
        }
        return state
    }

    /// Resets the puzzle to its starting position so the user can try again.
    func tryAgain() {
        let position = Position(fen: puzzle.fen) ?? .standard
        game.reset(to: position)
        moveIndex = 0
        state = .inProgress
    }
}

private extension Array {
    subscript(safeIndex idx: Int) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}
