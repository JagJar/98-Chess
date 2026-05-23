import ChessKit
import SwiftUI

struct ContentView: View {
    @State private var game = GameViewModel()
    @State private var engine: StockfishEngine?
    @State private var isThinking = false

    private let engineDepth = 5
    private let engineSkill = 5

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                if engine == nil || isThinking {
                    ProgressView().controlSize(.small)
                }
                Text(statusText)
                    .font(.headline)
            }
            .padding(.top)

            BoardView(game: game, canInteract: canInteract)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Undo") {
                    game.undo()
                    game.undo()
                }
                .disabled(game.moves.count < 2 || isThinking || engine == nil)

                Button("New Game") {
                    game.reset()
                }
                .disabled(isThinking)
            }
            .padding(.bottom)
        }
        .task {
            let e = StockfishEngine()
            await e.start()
            await e.setSkillLevel(engineSkill)
            engine = e
        }
        .onChange(of: game.sideToMove) { _, newSide in
            if engine != nil, newSide == .black, !game.isGameOver {
                Task { await playEngineMove() }
            }
        }
    }

    private var canInteract: Bool {
        engine != nil
            && !isThinking
            && game.sideToMove == .white
            && !game.isGameOver
    }

    private func playEngineMove() async {
        guard let engine else { return }
        isThinking = true
        let uci = try? await engine.bestMove(forFEN: game.fen, depth: engineDepth)
        isThinking = false
        if let uci {
            game.makeUCIMove(uci)
        }
    }

    private var statusText: String {
        if engine == nil { return "Loading engine…" }
        if isThinking { return "Computer thinking…" }
        switch game.state {
        case .active:
            return game.sideToMove == .white ? "Your turn" : "Computer's turn"
        case .check(let color):
            return color == .white ? "You're in check" : "Computer is in check"
        case .checkmate(let color):
            return color == .white ? "Checkmate — Computer wins" : "Checkmate — You win!"
        case .draw(let reason):
            return "Draw (\(drawLabel(reason)))"
        case .promotion:
            return "Promoting…"
        }
    }

    private func drawLabel(_ reason: Board.State.DrawReason) -> String {
        switch reason {
        case .stalemate:            "stalemate"
        case .fiftyMoves:           "50-move rule"
        case .insufficientMaterial: "insufficient material"
        case .repetition:           "threefold repetition"
        case .agreement:            "agreement"
        }
    }
}

#Preview {
    // In Xcode Previews the engine has no NNUE files and stays in "Loading…"
    ContentView()
}
