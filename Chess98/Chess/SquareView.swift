import ChessKit
import SwiftUI

struct SquareView: View {
    let square: Square
    let piece: Piece?
    let isLight: Bool
    let isSelected: Bool
    let isLegalDestination: Bool
    let isLastMoveSquare: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isLight ? Win98.Palette.lightSquare : Win98.Palette.darkSquare)

            if isLastMoveSquare {
                Rectangle().fill(Color.yellow.opacity(0.45))
            }
            if isSelected {
                Rectangle().fill(Win98.Palette.selection.opacity(0.45))
            }

            GeometryReader { geo in
                if let piece {
                    PieceView(piece: piece)
                        .font(.system(size: geo.size.width * 0.78))
                        .frame(width: geo.size.width, height: geo.size.height)
                }

                if isLegalDestination {
                    if piece == nil {
                        Circle()
                            .fill(Color.black.opacity(0.25))
                            .frame(width: geo.size.width * 0.28, height: geo.size.width * 0.28)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    } else {
                        Circle()
                            .strokeBorder(Color.black.opacity(0.45), lineWidth: geo.size.width * 0.06)
                            .frame(width: geo.size.width * 0.92, height: geo.size.width * 0.92)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityIdentifier("square_\(square)")
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let squareName = "\(square)"
        guard let piece else { return "\(squareName), empty" }
        let color = piece.color == .white ? "white" : "black"
        let kind: String = switch piece.kind {
        case .king:   "king"
        case .queen:  "queen"
        case .rook:   "rook"
        case .bishop: "bishop"
        case .knight: "knight"
        case .pawn:   "pawn"
        }
        return "\(squareName), \(color) \(kind)"
    }
}
