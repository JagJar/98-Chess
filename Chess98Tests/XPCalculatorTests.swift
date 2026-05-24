import XCTest
@testable import Chess98

final class XPCalculatorTests: XCTestCase {

    // MARK: per-outcome XP

    func testWinXPScalesWithDifficulty() {
        XCTAssertEqual(XPCalculator.xp(for: .win, difficulty: .beginner), 5 + 10)
        XCTAssertEqual(XPCalculator.xp(for: .win, difficulty: .easy),     5 + 20)
        XCTAssertEqual(XPCalculator.xp(for: .win, difficulty: .medium),   5 + 40)
        XCTAssertEqual(XPCalculator.xp(for: .win, difficulty: .hard),     5 + 80)
        XCTAssertEqual(XPCalculator.xp(for: .win, difficulty: .master),   5 + 150)
    }

    func testDrawXPIsDifficultyIndependent() {
        for diff in Difficulty.allCases {
            XCTAssertEqual(
                XPCalculator.xp(for: .draw, difficulty: diff),
                5 + 15,
                "draw XP should be flat regardless of difficulty (got differing value at \(diff))"
            )
        }
    }

    func testLossAndResignAwardBaseOnly() {
        for diff in Difficulty.allCases {
            XCTAssertEqual(XPCalculator.xp(for: .loss,   difficulty: diff), 5)
            XCTAssertEqual(XPCalculator.xp(for: .resign, difficulty: diff), 5)
        }
    }

    // MARK: puzzle constants

    func testPuzzleConstantsMatchPlan() {
        XCTAssertEqual(XPCalculator.perPuzzleSolve, 25)
        XCTAssertEqual(XPCalculator.noHintBonus,    10)
        XCTAssertEqual(XPCalculator.basePerGame,    5)
        XCTAssertEqual(XPCalculator.drawBonus,      15)
    }

    // MARK: streak milestones

    func testStreakMilestoneBonuses() {
        XCTAssertEqual(XPCalculator.streakMilestoneBonus(forNewStreak: 7),   50)
        XCTAssertEqual(XPCalculator.streakMilestoneBonus(forNewStreak: 30),  200)
        XCTAssertEqual(XPCalculator.streakMilestoneBonus(forNewStreak: 100), 500)
    }

    func testStreakMilestoneZeroAtNonMilestones() {
        for streak in [0, 1, 2, 3, 6, 8, 29, 31, 99, 101] {
            XCTAssertEqual(
                XPCalculator.streakMilestoneBonus(forNewStreak: streak),
                0,
                "expected no bonus at non-milestone streak \(streak)"
            )
        }
    }

    // MARK: level boundaries

    func testLevelFormulaBoundaryCases() {
        // level = floor(sqrt(xp / 50)) + 1
        let stats = PlayerStats()
        stats.xpTotal = 0
        XCTAssertEqual(stats.level, 1)

        stats.xpTotal = 49
        XCTAssertEqual(stats.level, 1, "below first threshold stays at level 1")

        stats.xpTotal = 50
        XCTAssertEqual(stats.level, 2, "exactly first threshold reaches level 2")

        stats.xpTotal = 199
        XCTAssertEqual(stats.level, 2, "below 200 stays at level 2")

        stats.xpTotal = 200
        XCTAssertEqual(stats.level, 3, "exactly 200 reaches level 3")

        stats.xpTotal = 800
        XCTAssertEqual(stats.level, 5, "exactly 800 (50 * 4²) reaches level 5")

        stats.xpTotal = 4050
        XCTAssertEqual(stats.level, 10, "exactly 4050 (50 * 9²) reaches level 10")
    }

    func testXpForLevelInverseMatches() {
        for level in 1...12 {
            let threshold = PlayerStats.xpForLevel(level)
            let stats = PlayerStats()
            stats.xpTotal = threshold
            XCTAssertEqual(
                stats.level,
                level,
                "stats at threshold for level \(level) should report that level"
            )
        }
    }
}
