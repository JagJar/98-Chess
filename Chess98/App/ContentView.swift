import ChessKit
import SwiftUI

struct ContentView: View {
    @State private var game = GameViewModel()

    var body: some View {
        VStack(spacing: 12) {
            Text(statusText)
                .font(.headline)
                .padding(.top)

            BoardView(game: game)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Undo") { game.undo() }
                    .disabled(game.moves.isEmpty)
                Button("New Game") { game.reset() }
            }
            .padding(.bottom)
        }
    }

    private var statusText: String {
        switch game.state {
        case .active:
            "\(game.sideToMove == .white ? "White" : "Black") to move"
        case .check(let color):
            "\(color == .white ? "White" : "Black") is in check"
        case .checkmate(let color):
            "Checkmate — \(color == .white ? "Black" : "White") wins"
        case .draw(let reason):
            "Draw (\(drawLabel(reason)))"
        case .promotion:
            "Promoting…"
        }
    }

    private func drawLabel(_ reason: Board.State.DrawReason) -> String {
        switch reason {
        case .stalemate: "stalemate"
        case .fiftyMoves: "50-move rule"
        case .insufficientMaterial: "insufficient material"
        case .repetition: "threefold repetition"
        case .agreement: "agreement"
        }
    }
}

#Preview {
    ContentView()
}
