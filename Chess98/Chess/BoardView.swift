import ChessKit
import SwiftUI

struct BoardView: View {
    @Bindable var game: GameViewModel
    @State private var selectedSquare: Square?

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let squareSize = side / 8

            VStack(spacing: 0) {
                ForEach(Self.ranksTopDown, id: \.self) { rank in
                    HStack(spacing: 0) {
                        ForEach(Square.File.allCases, id: \.self) { file in
                            let square = Square("\(file.rawValue)\(rank)")
                            SquareView(
                                square: square,
                                piece: game.piece(at: square),
                                isLight: isLight(file: file, rank: rank),
                                isSelected: selectedSquare == square,
                                isLegalDestination: legalDestinations.contains(square),
                                isLastMoveSquare: lastMoveSquares.contains(square),
                                onTap: { handleTap(square) }
                            )
                            .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private static let ranksTopDown: [Int] = Array((1...8).reversed())

    private func isLight(file: Square.File, rank: Int) -> Bool {
        (file.number + rank).isMultiple(of: 2)
    }

    private var legalDestinations: [Square] {
        guard let selectedSquare else { return [] }
        return game.legalMoves(from: selectedSquare)
    }

    private var lastMoveSquares: [Square] {
        guard let last = game.moves.last else { return [] }
        return [last.start, last.end]
    }

    private func handleTap(_ square: Square) {
        if let selected = selectedSquare {
            if selected == square {
                selectedSquare = nil
            } else if legalDestinations.contains(square) {
                let promotion: Piece.Kind? = needsPromotion(from: selected, to: square) ? .queen : nil
                _ = game.makeMove(from: selected, to: square, promotion: promotion)
                selectedSquare = nil
            } else if let piece = game.piece(at: square), piece.color == game.sideToMove {
                selectedSquare = square
            } else {
                selectedSquare = nil
            }
        } else if let piece = game.piece(at: square), piece.color == game.sideToMove {
            selectedSquare = square
        }
    }

    private func needsPromotion(from: Square, to: Square) -> Bool {
        guard let piece = game.piece(at: from), piece.kind == .pawn else { return false }
        let lastRank: Square.Rank = piece.color == .white ? 8 : 1
        return to.rank == lastRank
    }
}
