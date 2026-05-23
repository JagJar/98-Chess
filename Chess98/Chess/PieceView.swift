import ChessKit
import SwiftUI

struct PieceView: View {
    let piece: Piece

    var body: some View {
        PieceSprite(piece: piece)
            .padding(4)
    }
}
