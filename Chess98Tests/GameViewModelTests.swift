import XCTest
import ChessKit
@testable import Chess98

final class GameViewModelTests: XCTestCase {

    // MARK: Initial state

    func testInitialStateIsStandardOpeningPosition() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.fen, Position.standard.fen)
        XCTAssertEqual(vm.sideToMove, .white)
        XCTAssertEqual(vm.state, .active)
        XCTAssertTrue(vm.moves.isEmpty)
        XCTAssertFalse(vm.isGameOver)
    }

    // MARK: Move legality

    func testMakesLegalMove() {
        let vm = GameViewModel()
        let move = vm.makeMove(from: .e2, to: .e4)
        XCTAssertNotNil(move)
        XCTAssertEqual(vm.sideToMove, .black)
        XCTAssertEqual(vm.moves.count, 1)
        XCTAssertEqual(vm.sanMoves, ["e4"])
    }

    func testRejectsIllegalMove() {
        let vm = GameViewModel()
        let move = vm.makeMove(from: .e2, to: .e5) // pawn can't go two-then-one
        XCTAssertNil(move)
        XCTAssertEqual(vm.sideToMove, .white)
        XCTAssertTrue(vm.moves.isEmpty)
    }

    // MARK: Checkmates

    func testFoolsMate() {
        let vm = GameViewModel()
        let plies = ["f2f3", "e7e5", "g2g4", "d8h4"]
        for ply in plies {
            XCTAssertNotNil(vm.makeUCIMove(ply), "ply '\(ply)' should be legal")
        }
        XCTAssertEqual(vm.state, .checkmate(color: .white))
        XCTAssertTrue(vm.isGameOver)
        XCTAssertTrue(vm.sanMoves.last?.hasSuffix("#") ?? false)
    }

    func testScholarsMate() {
        let vm = GameViewModel()
        let plies = ["e2e4", "e7e5", "f1c4", "b8c6", "d1h5", "g8f6", "h5f7"]
        for ply in plies {
            XCTAssertNotNil(vm.makeUCIMove(ply), "ply '\(ply)' should be legal")
        }
        XCTAssertEqual(vm.state, .checkmate(color: .black))
        XCTAssertTrue(vm.isGameOver)
    }

    // MARK: Draws

    func testStalemate() {
        // White: K f6, Q e6. Black: K h8. White to move plays Qe6-f7,
        // leaving black with no legal moves and not in check.
        let setup = "7k/8/4QK2/8/8/8/8/8 w - - 0 1"
        let vm = GameViewModel(startingPosition: Position(fen: setup)!)
        XCTAssertNotNil(vm.makeMove(from: .e6, to: .f7))
        XCTAssertEqual(vm.state, .draw(reason: .stalemate))
        XCTAssertTrue(vm.isGameOver)
    }

    func testInsufficientMaterial() {
        // Black to move; KxN reduces position to K vs K.
        let setup = "8/8/8/3k4/4N3/8/8/4K3 b - - 0 1"
        let vm = GameViewModel(startingPosition: Position(fen: setup)!)
        XCTAssertNotNil(vm.makeMove(from: .d5, to: .e4))
        XCTAssertEqual(vm.state, .draw(reason: .insufficientMaterial))
        XCTAssertTrue(vm.isGameOver)
    }

    func testFiftyMoveRule() {
        // Halfmove clock at 99; one quiet king move tips it to 100.
        let setup = "k7/8/3K4/8/8/8/8/8 w - - 99 50"
        let vm = GameViewModel(startingPosition: Position(fen: setup)!)
        XCTAssertNotNil(vm.makeMove(from: .d6, to: .d5))
        XCTAssertEqual(vm.state, .draw(reason: .fiftyMoves))
    }

    func testThreefoldRepetition() {
        // Shuffling knights returns the position to start twice more,
        // making the starting position appear three times total.
        let vm = GameViewModel()
        let shuffle = [
            "g1f3", "g8f6", "f3g1", "f6g8",
            "g1f3", "g8f6", "f3g1", "f6g8"
        ]
        for ply in shuffle {
            XCTAssertNotNil(vm.makeUCIMove(ply))
        }
        XCTAssertEqual(vm.state, .draw(reason: .repetition))
    }

    // MARK: Undo

    func testUndoRestoresPreviousPosition() {
        let vm = GameViewModel()
        let originalFEN = vm.fen
        XCTAssertNotNil(vm.makeMove(from: .e2, to: .e4))
        XCTAssertNotEqual(vm.fen, originalFEN)

        XCTAssertTrue(vm.undo())
        XCTAssertEqual(vm.fen, originalFEN)
        XCTAssertEqual(vm.sideToMove, .white)
        XCTAssertTrue(vm.moves.isEmpty)
    }

    func testUndoOnEmptyHistoryReturnsFalse() {
        let vm = GameViewModel()
        XCTAssertFalse(vm.undo())
    }

    func testUndoUnwindsCheckmate() {
        let vm = GameViewModel()
        let plies = ["f2f3", "e7e5", "g2g4", "d8h4"]
        for ply in plies { vm.makeUCIMove(ply) }
        XCTAssertEqual(vm.state, .checkmate(color: .white))

        XCTAssertTrue(vm.undo())
        XCTAssertEqual(vm.state, .active)
        XCTAssertEqual(vm.sideToMove, .black)
        XCTAssertFalse(vm.isGameOver)
    }

    // MARK: Promotion

    func testPromotionViaExplicitPromotionKind() {
        // Lone white pawn on the 7th, promoting on e8.
        let setup = "8/4P3/8/8/k7/8/8/4K3 w - - 0 1"
        let vm = GameViewModel(startingPosition: Position(fen: setup)!)
        let move = vm.makeMove(from: .e7, to: .e8, promotion: .queen)
        XCTAssertNotNil(move)
        XCTAssertEqual(move?.promotedPiece?.kind, .queen)
        XCTAssertTrue(vm.fen.hasPrefix("4Q3"))
    }

    func testPromotionViaUCISuffix() {
        let setup = "8/4P3/8/8/k7/8/8/4K3 w - - 0 1"
        let vm = GameViewModel(startingPosition: Position(fen: setup)!)
        let move = vm.makeUCIMove("e7e8q")
        XCTAssertNotNil(move)
        XCTAssertEqual(move?.promotedPiece?.kind, .queen)
    }

    func testPromotionWithoutChoiceRollsBack() {
        let setup = "8/4P3/8/8/k7/8/8/4K3 w - - 0 1"
        let vm = GameViewModel(startingPosition: Position(fen: setup)!)
        let originalFEN = vm.fen
        let move = vm.makeMove(from: .e7, to: .e8, promotion: nil)
        XCTAssertNil(move)
        XCTAssertEqual(vm.fen, originalFEN)
        XCTAssertTrue(vm.moves.isEmpty)
    }

    // MARK: Reset

    func testResetReturnsToStartingPosition() {
        let vm = GameViewModel()
        vm.makeUCIMove("e2e4")
        vm.makeUCIMove("e7e5")
        XCTAssertEqual(vm.moves.count, 2)

        vm.reset()
        XCTAssertEqual(vm.fen, Position.standard.fen)
        XCTAssertEqual(vm.sideToMove, .white)
        XCTAssertTrue(vm.moves.isEmpty)
    }
}
