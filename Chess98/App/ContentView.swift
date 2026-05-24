import ChessKit
import SwiftData
import SwiftUI
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Query(sort: \SavedGame.updatedAt, order: .reverse) private var savedGames: [SavedGame]
    @Query private var unlockedAchievements: [UnlockedAchievement]

    @AppStorage("difficulty") private var difficulty: Difficulty = .easy

    @State private var game = GameViewModel()
    @State private var engine: StockfishEngine?
    @State private var isThinking = false
    @State private var openMenuID: String?
    @State private var activeDialog: ActiveDialog?
    @State private var pendingPromotion: PendingPromotion?
    @State private var retention: RetentionService?
    @State private var hasReportedThisGame = false
    @State private var pendingAchievements: [Achievement] = []
    @State private var currentAchievementToast: Achievement?
    @State private var puzzleVM: PuzzleViewModel?
    @State private var onboardingStep: OnboardingStep?
    @State private var onboardingHour = 19
    @State private var onboardingMinute = 0
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    private let notifications = NotificationScheduler()

    private enum ActiveDialog: Identifiable {
        case confirmResign
        case about
        case stats
        case freezeUsed
        case achievements
        case notifications

        var id: String {
            switch self {
            case .confirmResign: "confirm-resign"
            case .about:         "about"
            case .stats:         "stats"
            case .freezeUsed:    "freeze-used"
            case .achievements:  "achievements"
            case .notifications: "notifications"
            }
        }
    }

    private var unlockedAchievementIDs: Set<String> {
        Set(unlockedAchievements.map(\.achievementID))
    }

    private var hasUnreadAchievements: Bool {
        unlockedAchievements.contains(where: \.isNew)
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
                Win98Window(
                    title: "Chess 98",
                    content: {
                        VStack(spacing: 6) {
                            Win98MenuBar(menus: menus, openMenuID: $openMenuID)
                                .win98Bevel(.outset)
                                .zIndex(10)

                            gameContent
                                .contentShape(Rectangle())
                                .onTapGesture { openMenuID = nil }
                        }
                    },
                    trailing: {
                        if let retention {
                            StreakBadge(
                                streak: retention.stats.currentStreak,
                                onTap: { activeDialog = .stats }
                            )
                        }
                    }
                )
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
                case .stats:         statsDialog
                case .freezeUsed:    freezeUsedDialog
                case .achievements:  achievementsDialog
                case .notifications: notificationsDialog
                }
            }

            // Onboarding takes precedence over achievement toasts so the user
            // sees the welcome flow before celebrations.
            if let step = onboardingStep {
                switch step {
                case .welcome:        onboardingWelcomeDialog
                case .dailyReminder:  onboardingReminderDialog
                }
            } else if let ach = currentAchievementToast {
                AchievementUnlockedDialog(achievement: ach, onDismiss: dismissCurrentAchievement)
            }
        }
        // Win98 chrome is fixed-pixel; lock visual size while leaving
        // VoiceOver labels intact for screen-reader users.
        .dynamicTypeSize(.large)
        .task {
            restoreSavedGameIfAny()

            let retentionService = RetentionService(context: modelContext)
            retentionService.onAppLaunch()
            retention = retentionService
            // If we restored a game that was already over, don't report it
            // as a fresh completion next time isGameOver flips.
            hasReportedThisGame = game.isGameOver

            // Surface the one-time "freeze used" toast if a streak freeze
            // was auto-applied during onAppLaunch.
            if retentionService.stats.freezeUsedOn != nil, activeDialog == nil {
                activeDialog = .freezeUsed
            }

            // Kick off onboarding on first launch.
            if !retentionService.stats.onboardingCompleted {
                onboardingHour = retentionService.stats.notificationHour
                onboardingMinute = retentionService.stats.notificationMinute
                onboardingStep = .welcome
            }

            // Refresh notification body batch + auth status when the app
            // appears (so a streak update is reflected in upcoming reminders).
            notificationAuthStatus = await notifications.authorizationStatus()
            if retentionService.stats.notificationsEnabled, notificationAuthStatus == .authorized {
                await notifications.rescheduleDailyReminders(
                    hour: retentionService.stats.notificationHour,
                    minute: retentionService.stats.notificationMinute,
                    bodyProvider: { dayOffset in
                        DailyReminderBody.body(forDayOffset: dayOffset, stats: retentionService.stats)
                    }
                )
            }

            let e = StockfishEngine()
            await e.start()
            await e.setSkillLevel(difficulty.skillLevel)
            engine = e

            if game.sideToMove == .black, !game.isGameOver, pendingPromotion == nil {
                await playEngineMove()
            }
        }
        .onChange(of: game.isGameOver) { wasOver, isOver in
            if !wasOver, isOver, !hasReportedThisGame {
                reportGameCompletion()
            }
        }
        .onChange(of: difficulty) { _, new in
            Task { await engine?.setSkillLevel(new.skillLevel) }
        }
        .onChange(of: game.sanMoves.count) { oldCount, newCount in
            if newCount > oldCount, let lastMove = game.moves.last {
                Haptics.play(for: lastMove, gameOver: game.isGameOver)
            }
            persistState()
        }
        .onChange(of: game.sideToMove) { _, newSide in
            if engine != nil, newSide == .black, !game.isGameOver, pendingPromotion == nil {
                Task { await playEngineMove() }
            }
        }
    }

    // MARK: - Layout

    private var isWideLayout: Bool {
        // iPad in any orientation, or iPhone in landscape — show board + history side-by-side.
        hSizeClass == .regular || vSizeClass == .compact
    }

    @ViewBuilder
    private var gameContent: some View {
        if let vm = puzzleVM {
            puzzleContent(vm: vm)
        } else if isWideLayout {
            HStack(alignment: .top, spacing: 6) {
                VStack(spacing: 6) {
                    statusBar
                    boardView
                        .frame(maxWidth: 560, maxHeight: 560)
                }
                MoveHistoryView(sanMoves: game.sanMoves)
                    .frame(minWidth: 160, idealWidth: 200, maxWidth: 240)
                    .frame(maxHeight: 600)
            }
            .frame(maxWidth: 820, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            VStack(spacing: 6) {
                statusBar
                boardView
                MoveHistoryView(sanMoves: game.sanMoves)
                    .frame(height: 90)
            }
        }
    }

    @ViewBuilder
    private func puzzleContent(vm: PuzzleViewModel) -> some View {
        VStack(spacing: 6) {
            puzzleBanner(vm: vm)
            BoardView(
                game: vm.game,
                canInteract: vm.state == .inProgress
            )
            .win98Bevel(.inset)
            .onChange(of: vm.game.sanMoves.count) { oldCount, newCount in
                guard newCount > oldCount else { return }
                handlePuzzleMove(vm: vm)
            }
            puzzleControls(vm: vm)
        }
    }

    private func puzzleBanner(vm: PuzzleViewModel) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Daily Puzzle · \(vm.puzzle.title)")
                    .font(.system(size: 12, weight: .semibold))
                Text(puzzleStatusText(vm: vm))
                    .font(.system(size: 11))
                    .foregroundStyle(Win98.Palette.shadow)
            }
            Spacer(minLength: 0)
            Button("Back to Game", action: closePuzzle)
                .buttonStyle(.win98)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Win98.Palette.face)
        .win98Bevel(.outset)
    }

    private func puzzleControls(vm: PuzzleViewModel) -> some View {
        HStack(spacing: 6) {
            if let hint = vm.puzzle.hint, vm.state == .wrongMove || vm.state == .inProgress {
                Text("Hint: \(hint)")
                    .font(.system(size: 11))
                    .foregroundStyle(Win98.Palette.shadow)
                    .lineLimit(2)
            }
            Spacer()
            if vm.state == .wrongMove {
                Button("Try Again") { vm.tryAgain() }
                    .buttonStyle(.win98)
            }
        }
        .padding(.horizontal, 6)
    }

    private func puzzleStatusText(vm: PuzzleViewModel) -> String {
        switch vm.state {
        case .inProgress: return "Find the best move."
        case .wrongMove:  return "Not quite — try again."
        case .solved:     return "Solved! Well done."
        }
    }

    private func handlePuzzleMove(vm: PuzzleViewModel) {
        let priorState = vm.state
        let newState = vm.validateLastMove()
        if priorState != .solved, newState == .solved {
            let report = retention?.onPuzzleSolved(
                puzzleID: vm.puzzle.id,
                fromHint: false
            )
            if let report {
                pendingAchievements.append(contentsOf: report.newlyUnlockedAchievements)
                showNextAchievement()
            }
        } else if newState == .wrongMove {
            retention?.recordPuzzleAttempt(puzzleID: vm.puzzle.id)
        }
    }

    private func openDailyPuzzle() {
        guard let puzzle = PuzzleCatalog.today() else { return }
        puzzleVM = PuzzleViewModel(puzzle: puzzle)
    }

    private func closePuzzle() {
        puzzleVM = nil
    }

    private var isPuzzleSolvedToday: Bool {
        retention?.stats.puzzlesSolvedToday ?? false
    }

    private var boardView: some View {
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
    }

    // MARK: - Menus

    private var menus: [Win98Menu] {
        [
            Win98Menu(id: "game", title: "Game", items: [
                .action(id: "new", label: "New Game", action: newGame),
                .action(id: "undo", label: "Undo", action: undo),
                .separator(id: "sep1"),
                .action(
                    id: "daily-puzzle",
                    label: isPuzzleSolvedToday ? "Daily Puzzle…" : "Daily Puzzle… (!)",
                    action: openDailyPuzzle
                ),
                .separator(id: "sep2"),
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
            Win98Menu(
                id: "tools",
                title: hasUnreadAchievements ? "Tools (!)" : "Tools",
                items: [
                    .action(id: "stats", label: "Stats…", action: { activeDialog = .stats }),
                    .action(
                        id: "achievements",
                        label: hasUnreadAchievements ? "Achievements… (!)" : "Achievements…",
                        action: { activeDialog = .achievements }
                    ),
                    .separator(id: "tools-sep"),
                    .action(id: "notifications", label: "Notifications…", action: openNotificationsDialog)
                ]
            ),
            Win98Menu(id: "help", title: "Help", items: [
                .action(id: "about", label: "About Chess 98", action: { activeDialog = .about })
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

    private var freezeUsedDialog: some View {
        Win98Dialog(title: "Streak Freeze Used", onClose: dismissFreezeDialog) {
            VStack(alignment: .leading, spacing: 8) {
                Text("You missed a day, but a streak freeze kept your streak alive.")
                Text("A new freeze refills next Monday.")
                    .foregroundStyle(Win98.Palette.shadow)
                HStack {
                    Spacer()
                    Button("OK", action: dismissFreezeDialog)
                        .buttonStyle(.win98)
                }
                .padding(.top, 6)
            }
            .font(.system(size: 12))
            .foregroundStyle(Win98.Palette.text)
        }
    }

    private func dismissFreezeDialog() {
        retention?.clearFreezeNotice()
        activeDialog = nil
    }

    private var onboardingWelcomeDialog: some View {
        OnboardingWelcomeDialog {
            onboardingStep = .dailyReminder
        }
    }

    private var onboardingReminderDialog: some View {
        OnboardingDailyReminderDialog(
            hour: $onboardingHour,
            minute: $onboardingMinute,
            onYes: { Task { await acceptDailyReminder() } },
            onNo: { declineDailyReminder() }
        )
    }

    private func acceptDailyReminder() async {
        let granted = await notifications.requestPermission()
        notificationAuthStatus = await notifications.authorizationStatus()
        retention?.setNotificationPreferences(
            enabled: granted,
            hour: onboardingHour,
            minute: onboardingMinute
        )
        if granted, let stats = retention?.stats {
            await notifications.rescheduleDailyReminders(
                hour: stats.notificationHour,
                minute: stats.notificationMinute,
                bodyProvider: { DailyReminderBody.body(forDayOffset: $0, stats: stats) }
            )
        }
        retention?.completeOnboarding()
        onboardingStep = nil
    }

    private func declineDailyReminder() {
        retention?.setNotificationPreferences(
            enabled: false,
            hour: onboardingHour,
            minute: onboardingMinute
        )
        retention?.completeOnboarding()
        onboardingStep = nil
    }

    @ViewBuilder
    private var notificationsDialog: some View {
        if let retention {
            NotificationSettingsDialog(
                enabled: Binding(
                    get: { retention.stats.notificationsEnabled },
                    set: { _ in /* updated via onCommit */ }
                ),
                hour: Binding(
                    get: { retention.stats.notificationHour },
                    set: { retention.stats.notificationHour = $0 }
                ),
                minute: Binding(
                    get: { retention.stats.notificationMinute },
                    set: { retention.stats.notificationMinute = $0 }
                ),
                authorizationStatus: notificationAuthStatus,
                onClose: { activeDialog = nil },
                onCommit: { Task { await applyNotificationPrefs() } }
            )
        }
    }

    private func openNotificationsDialog() {
        Task {
            notificationAuthStatus = await notifications.authorizationStatus()
            activeDialog = .notifications
        }
    }

    private func applyNotificationPrefs() async {
        guard let retention else { return }
        let stats = retention.stats
        retention.setNotificationPreferences(
            enabled: stats.notificationsEnabled,
            hour: stats.notificationHour,
            minute: stats.notificationMinute
        )
        if stats.notificationsEnabled {
            if notificationAuthStatus == .notDetermined {
                _ = await notifications.requestPermission()
                notificationAuthStatus = await notifications.authorizationStatus()
            }
            if notificationAuthStatus == .authorized {
                await notifications.rescheduleDailyReminders(
                    hour: stats.notificationHour,
                    minute: stats.notificationMinute,
                    bodyProvider: { DailyReminderBody.body(forDayOffset: $0, stats: stats) }
                )
            }
        } else {
            await notifications.cancelAll()
        }
    }

    private var achievementsDialog: some View {
        AchievementsWindow(
            unlockedIDs: unlockedAchievementIDs,
            onClose: {
                retention?.markAchievementsRead()
                activeDialog = nil
            }
        )
    }

    @ViewBuilder
    private var statsDialog: some View {
        if let retention {
            StatsWindow(stats: retention.stats, onClose: { activeDialog = nil })
        } else {
            Win98Dialog(title: "Stats", onClose: { activeDialog = nil }) {
                Text("Loading…")
                    .font(.system(size: 12))
                    .foregroundStyle(Win98.Palette.text)
            }
        }
    }

    private var aboutDialog: some View {
        Win98Dialog(title: "About Chess 98", onClose: { activeDialog = nil }) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Chess 98").font(.system(size: 14, weight: .bold))
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
        hasReportedThisGame = false
    }

    private func reportGameCompletion() {
        guard let retention else { return }
        hasReportedThisGame = true
        let outcome = deriveOutcome()
        let report = retention.onGameFinished(
            outcome: outcome,
            difficulty: difficulty,
            moveCount: game.sanMoves.count
        )
        pendingAchievements.append(contentsOf: report.newlyUnlockedAchievements)
        showNextAchievement()
    }

    private func showNextAchievement() {
        guard currentAchievementToast == nil, !pendingAchievements.isEmpty else { return }
        currentAchievementToast = pendingAchievements.removeFirst()
    }

    private func dismissCurrentAchievement() {
        currentAchievementToast = nil
        showNextAchievement()
    }

    private func deriveOutcome() -> GameOutcome {
        if let resigned = game.resignation {
            return resigned == .white ? .resign : .win
        }
        switch game.state {
        case .checkmate(let matedColor):
            return matedColor == .white ? .loss : .win
        case .draw:
            return .draw
        default:
            return .draw
        }
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
