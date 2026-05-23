import ChessKit
import SwiftUI

struct ContentView: View {
    @State private var game = GameViewModel()
    @State private var engine: StockfishEngine?
    @State private var isThinking = false

    private let engineDepth = 5
    private let engineSkill = 5

    var body: some View {
        ZStack {
            Win98.Palette.desktop.ignoresSafeArea()

            Win98Window(title: "98 Chess") {
                VStack(spacing: 8) {
                    statusBar
                    BoardView(game: game, canInteract: canInteract)
                        .win98Bevel(.inset)
                    HStack(spacing: 6) {
                        Spacer()
                        Button("Undo") {
                            game.undo()
                            game.undo()
                        }
                        .buttonStyle(.win98)
                        .disabled(game.moves.count < 2 || isThinking || engine == nil)

                        Button("New Game") {
                            game.reset()
                        }
                        .buttonStyle(.win98)
                        .disabled(isThinking)
                    }
                }
            }
            .padding(12)
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

    private var statusBar: some View {
        HStack(spacing: 6) {
            if engine == nil || isThinking {
                ProgressView().controlSize(.mini)
            }
            Text(statusText)
                .font(.system(size: 12))
                .foregroundStyle(Win98.Palette.text)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity)
        .background(Win98.Palette.face)
        .win98Bevel(.inset)
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
    ContentView()
}
