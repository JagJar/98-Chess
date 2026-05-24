import XCTest
@testable import Chess98

final class AchievementEvaluatorTests: XCTestCase {

    // MARK: filtering vs the unlocked set

    func testAlreadyUnlockedAchievementsAreExcluded() {
        let stats = PlayerStats()
        stats.gamesPlayed = 1
        stats.wins = 1
        let ctx = AchievementContext(stats: stats, lastResult: nil)

        let firstPass = AchievementEvaluator.newlyUnlocked(
            in: ctx,
            alreadyUnlocked: []
        )
        XCTAssertTrue(firstPass.contains { $0.id == "first_game" })
        XCTAssertTrue(firstPass.contains { $0.id == "first_win" })

        let secondPass = AchievementEvaluator.newlyUnlocked(
            in: ctx,
            alreadyUnlocked: ["first_game", "first_win"]
        )
        XCTAssertFalse(secondPass.contains { $0.id == "first_game" })
        XCTAssertFalse(secondPass.contains { $0.id == "first_win" })
    }

    // MARK: individual predicates

    func testFirstGameUnlockedAtSingleGame() {
        let stats = PlayerStats()
        stats.gamesPlayed = 1
        let result = newlyUnlockedIDs(for: stats)
        XCTAssertTrue(result.contains("first_game"))
    }

    func testWin10UnlocksOnlyAtTen() {
        let stats = PlayerStats()
        stats.wins = 9
        XCTAssertFalse(newlyUnlockedIDs(for: stats).contains("win_10"))
        stats.wins = 10
        XCTAssertTrue(newlyUnlockedIDs(for: stats).contains("win_10"))
        stats.wins = 50
        XCTAssertTrue(newlyUnlockedIDs(for: stats).contains("win_10"))
    }

    func testBeatDifficultyAchievementsKeyOffWinsByDifficulty() {
        let stats = PlayerStats()
        stats.wins = 1
        stats.recordWin(difficultyRaw: Difficulty.easy.rawValue)

        let ids = newlyUnlockedIDs(for: stats)
        XCTAssertTrue(ids.contains("beat_easy"))
        XCTAssertFalse(ids.contains("beat_master"))

        stats.recordWin(difficultyRaw: Difficulty.master.rawValue)
        let ids2 = newlyUnlockedIDs(for: stats)
        XCTAssertTrue(ids2.contains("beat_master"))
    }

    func testStreakAchievementsUnlockAtThresholds() {
        let stats = PlayerStats()

        stats.currentStreak = 2
        XCTAssertFalse(newlyUnlockedIDs(for: stats).contains("streak_3"))

        stats.currentStreak = 3
        let three = newlyUnlockedIDs(for: stats)
        XCTAssertTrue(three.contains("streak_3"))
        XCTAssertFalse(three.contains("streak_7"))

        stats.currentStreak = 30
        let thirty = newlyUnlockedIDs(for: stats)
        XCTAssertTrue(thirty.contains("streak_3"))
        XCTAssertTrue(thirty.contains("streak_7"))
        XCTAssertTrue(thirty.contains("streak_30"))
    }

    func testQuickMateUnlocksOnlyOnWinAndShortGame() {
        let stats = PlayerStats()

        // Wrong outcome
        let losingResult = GameResult(
            dayKey: Date.now, outcome: .loss,
            difficultyRaw: Difficulty.easy.rawValue, moveCount: 10, xpAwarded: 5
        )
        let lossCtx = AchievementContext(stats: stats, lastResult: losingResult)
        XCTAssertFalse(
            AchievementEvaluator.newlyUnlocked(in: lossCtx, alreadyUnlocked: [])
                .contains { $0.id == "quick_mate" }
        )

        // Win but too many plies
        let longWin = GameResult(
            dayKey: Date.now, outcome: .win,
            difficultyRaw: Difficulty.easy.rawValue, moveCount: 21, xpAwarded: 25
        )
        let longCtx = AchievementContext(stats: stats, lastResult: longWin)
        XCTAssertFalse(
            AchievementEvaluator.newlyUnlocked(in: longCtx, alreadyUnlocked: [])
                .contains { $0.id == "quick_mate" }
        )

        // Win in exactly 20 plies → unlocks
        let quickWin = GameResult(
            dayKey: Date.now, outcome: .win,
            difficultyRaw: Difficulty.easy.rawValue, moveCount: 20, xpAwarded: 25
        )
        let quickCtx = AchievementContext(stats: stats, lastResult: quickWin)
        XCTAssertTrue(
            AchievementEvaluator.newlyUnlocked(in: quickCtx, alreadyUnlocked: [])
                .contains { $0.id == "quick_mate" }
        )

        // Quick win missing the result entirely → no unlock
        let noResultCtx = AchievementContext(stats: stats, lastResult: nil)
        XCTAssertFalse(
            AchievementEvaluator.newlyUnlocked(in: noResultCtx, alreadyUnlocked: [])
                .contains { $0.id == "quick_mate" }
        )
    }

    func testPuzzleAchievementsRequirePuzzleSolves() {
        let stats = PlayerStats()
        stats.puzzlesSolvedTotal = 0
        XCTAssertFalse(newlyUnlockedIDs(for: stats).contains("puzzle_first"))

        stats.puzzlesSolvedTotal = 1
        XCTAssertTrue(newlyUnlockedIDs(for: stats).contains("puzzle_first"))
        XCTAssertFalse(newlyUnlockedIDs(for: stats).contains("puzzle_10"))

        stats.puzzlesSolvedTotal = 10
        XCTAssertTrue(newlyUnlockedIDs(for: stats).contains("puzzle_10"))
    }

    // MARK: helper

    private func newlyUnlockedIDs(for stats: PlayerStats) -> Set<String> {
        let ctx = AchievementContext(stats: stats, lastResult: nil)
        return Set(
            AchievementEvaluator.newlyUnlocked(in: ctx, alreadyUnlocked: [])
                .map(\.id)
        )
    }
}
