import ChessKit
import Foundation
import Observation

@Observable
final class GameViewModel {
    private struct Ply {
        let priorBoard: Board
        let move: Move
    }

    private var board: Board
    private var history: [Ply] = []

    init(startingPosition: Position = .standard) {
        board = Board(position: startingPosition)
    }

    var fen: String { board.position.fen }
    var sideToMove: Piece.Color { board.position.sideToMove }
    var state: Board.State { board.state }
    var moves: [Move] { history.map(\.move) }
    var sanMoves: [String] { history.map { $0.move.san } }

    var isGameOver: Bool {
        switch board.state {
        case .checkmate, .draw: true
        default: false
        }
    }

    @discardableResult
    func makeMove(from: Square, to: Square, promotion: Piece.Kind? = nil) -> Move? {
        let snapshot = board

        guard let move = board.move(pieceAt: from, to: to) else {
            return nil
        }

        var finalMove = move

        if case let .promotion(pending) = board.state {
            guard let promotion else {
                board = snapshot
                return nil
            }
            finalMove = board.completePromotion(of: pending, to: promotion)
        }

        history.append(Ply(priorBoard: snapshot, move: finalMove))
        return finalMove
    }

    @discardableResult
    func makeUCIMove(_ uci: String) -> Move? {
        guard let parsed = EngineLANParser.parse(
            move: uci,
            for: board.position.sideToMove,
            in: board.position
        ) else {
            return nil
        }

        return makeMove(
            from: parsed.start,
            to: parsed.end,
            promotion: parsed.promotedPiece?.kind
        )
    }

    @discardableResult
    func undo() -> Bool {
        guard let last = history.popLast() else { return false }
        board = last.priorBoard
        return true
    }

    func reset(to position: Position = .standard) {
        board = Board(position: position)
        history.removeAll()
    }
}
