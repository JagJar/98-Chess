import ChessKit
import SwiftUI

struct PieceView: View {
    let piece: Piece

    var body: some View {
        Text(Self.symbol(for: piece))
            .foregroundStyle(.black)
            .minimumScaleFactor(0.5)
    }

    private static func symbol(for piece: Piece) -> String {
        // U+FE0E is the text-style variation selector. Without it iOS renders
        // the black chess codepoints (U+265A–U+265F) as colored emoji glyphs
        // that don't match the flat outline style of the white pieces.
        let textStyle = "\u{FE0E}"
        let base: String = switch (piece.color, piece.kind) {
        case (.white, .king):   "\u{2654}"
        case (.white, .queen):  "\u{2655}"
        case (.white, .rook):   "\u{2656}"
        case (.white, .bishop): "\u{2657}"
        case (.white, .knight): "\u{2658}"
        case (.white, .pawn):   "\u{2659}"
        case (.black, .king):   "\u{265A}"
        case (.black, .queen):  "\u{265B}"
        case (.black, .rook):   "\u{265C}"
        case (.black, .bishop): "\u{265D}"
        case (.black, .knight): "\u{265E}"
        case (.black, .pawn):   "\u{265F}"
        }
        return base + textStyle
    }
}
