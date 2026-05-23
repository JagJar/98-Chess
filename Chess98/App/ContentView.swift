import ChessKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedGame.updatedAt, order: .reverse) private var savedGames: [SavedGame]

    @AppStorage("difficulty") private var difficulty: Difficulty = .easy

    @State private var game = GameViewModel()
    @State private var engine: StockfishEngine?
    @State private var isThinking = false
    @State private var openMenuID: String?
    @State private var activeDialog: ActiveDialog?
    @State private var pendingPromotion: PendingPromotion?

    private enum ActiveDialog: Identifiable {
        case confirmResign
        case about

        var id: String {
            switch self {
            case .confirmResign: "confirm-resign"
            case .about:         "about"
            }
        }
    }

    private struct PendingPromotion {
        let from: Square
        let to: Square
        let color: Piece.Color
    }

    var body: some View {
        ZStack(alignment: .top) {
            Win98.Palette.desktop.ignoresSafeArea()

            VStack(spacing: 0) {
                Win98Window(title: "98 Chess") {
                    VStack(spacing: 6) {
                        Win98MenuBar(menus: menus, openMenuID: $openMenuID)
                            .win98Bevel(.outset)
                            .zIndex(10)

                        VStack(spacing: 6) {
                            statusBar
                            BoardView(
                                game: game,
                                canInteract: canInteract,
                                onPromotionNeeded: { from, to in
                                    pendingPromotion = PendingPromotion(
                                        from: from,
                                        to: to,
                                        color: game.sideToMove
                                    )
                                }
                            )
                            .win98Bevel(.inset)
                            MoveHistoryView(sanMoves: game.sanMoves)
                                .frame(height: 90)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { openMenuID = nil }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                Spacer(minLength: 0)
            }

            if let pending = pendingPromotion {
                promotionDialog(pending)
            } else if let dialog = activeDialog {
                switch dialog {
                case .confirmResign: resignConfirmDialog
                case .about:         aboutDialog
                }
            }
        }
        .task {
            restoreSavedGameIfAny()

            let e = StockfishEngine()
            await e.start()
            await e.setSkillLevel(difficulty.skillLevel)
            engine = e

            if game.sideToMove == .black, !game.isGameOver, pendingPromotion == nil {
                await playEngineMove()
            }
        }
        .onChange(of: difficulty) { _, new in
            Task { await engine?.setSkillLevel(new.skillLevel) }
        }
        .onChange(of: game.sanMoves.count) { _, _ in
            persistState()
        }
        .onChange(of: game.sideToMove) { _, newSide in
            if engine != nil, newSide == .black, !game.isGameOver, pendingPromotion == nil {
                Task { await playEngineMove() }
            }
        }
    }

    // MARK: - Menus

    private var menus: [Win98Menu] {
        [
            Win98Menu(id: "game", title: "Game", items: [
                .action(id: "new", label: "New Game", action: newGame),
                .action(id: "undo", label: "Undo", action: undo),
                .separator(id: "sep1"),
                .action(id: "resign", label: "Resign…", action: { activeDialog = .confirmResign })
            ]),
            Win98Menu(id: "difficulty", title: "Difficulty", items:
                Difficulty.allCases.map { diff in
                    .toggle(
                        id: diff.id,
                        label: diff.label,
                        isOn: difficulty == diff,
                        action: { difficulty = diff }
                    )
                }
            ),
            Win98Menu(id: "help", title: "Help", items: [
                .action(id: "about", label: "About 98 Chess", action: { activeDialog = .about })
            ])
        ]
    }

    // MARK: - Status bar

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

    // MARK: - Dialogs

    private func promotionDialog(_ p: PendingPromotion) -> some View {
        Win98Dialog(title: "Promote pawn") {
            VStack(spacing: 8) {
                Text("Choose a piece:")
                    .font(.system(size: 12))
                    .foregroundStyle(Win98.Palette.text)
                HStack(spacing: 6) {
                    ForEach([Piece.Kind.queen, .rook, .bishop, .knight], id: \.self) { kind in
                        Button {
                            _ = game.makeMove(from: p.from, to: p.to, promotion: kind)
                            pendingPromotion = nil
                        } label: {
                            PieceView(piece: Piece(kind, color: p.color, square: .a1))
                                .font(.system(size: 36))
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.win98)
                    }
                }
            }
        }
    }

    private var resignConfirmDialog: some View {
        Win98Dialog(title: "Resign", onClose: { activeDialog = nil }) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Resign this game? The computer will win.")
                    .font(.system(size: 12))
                    .foregroundStyle(Win98.Palette.text)
                HStack {
                    Spacer()
                    Button("Resign") {
                        game.resign()
                        clearSavedGame()
                        activeDialog = nil
                    }
                    .buttonStyle(.win98)
                    Button("Cancel") { activeDialog = nil }
                        .buttonStyle(.win98)
                }
            }
        }
    }

    private var aboutDialog: some View {
        Win98Dialog(title: "About 98 Chess", onClose: { activeDialog = nil }) {
            VStack(alignment: .leading, spacing: 6) {
                Text("98 Chess").font(.system(size: 14, weight: .bold))
                Text("Version 0.1.0")
                Text("A Windows 98 themed chess app for iOS.")
                    .padding(.bottom, 4)
                Text("Engine: Stockfish 17 (GPL v3)")
                    .font(.system(size: 11))
                    .foregroundStyle(Win98.Palette.shadow)
                HStack {
                    Spacer()
                    Button("OK") { activeDialog = nil }
                        .buttonStyle(.win98)
                }
                .padding(.top, 6)
            }
            .font(.system(size: 12))
            .foregroundStyle(Win98.Palette.text)
        }
    }

    // MARK: - State helpers

    private var canInteract: Bool {
        engine != nil
            && !isThinking
            && game.sideToMove == .white
            && !game.isGameOver
            && pendingPromotion == nil
    }

    private func newGame() {
        game.reset()
        clearSavedGame()
    }

    private func undo() {
        game.undo()
        game.undo()
    }

    private func playEngineMove() async {
        guard let engine else { return }
        isThinking = true
        let uci = try? await engine.bestMove(forFEN: game.fen, depth: difficulty.depth)
        isThinking = false
        if let uci {
            game.makeUCIMove(uci)
        }
    }

    // MARK: - Persistence

    private func restoreSavedGameIfAny() {
        guard let saved = savedGames.first else { return }
        let uciList = saved.uciMoves
            .split(separator: " ")
            .map(String.init)
        guard !uciList.isEmpty else { return }
        for uci in uciList {
            _ = game.makeUCIMove(uci)
        }
    }

    private func persistState() {
        if game.isGameOver {
            clearSavedGame()
            return
        }
        let uciHistory = game.moves
            .map { EngineLANParser.convert(move: $0) }
            .joined(separator: " ")
        if let existing = savedGames.first {
            existing.uciMoves = uciHistory
            existing.updatedAt = .now
        } else if !uciHistory.isEmpty {
            modelContext.insert(SavedGame(uciMoves: uciHistory))
        }
        try? modelContext.save()
    }

    private func clearSavedGame() {
        for saved in savedGames {
            modelContext.delete(saved)
        }
        try? modelContext.save()
    }

    // MARK: - Status text

    private var statusText: String {
        if engine == nil { return "Loading engine…" }
        if let resigned = game.resignation {
            return resigned == .white
                ? "You resigned — Computer wins"
                : "Computer resigned — You win!"
        }
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
        .modelContainer(for: SavedGame.self, inMemory: true)
}
