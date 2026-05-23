import XCTest
@testable import Chess98

final class StockfishEngineTests: XCTestCase {
    func testNNUEFilesAreBundled() {
        let small = Bundle.main.url(forResource: "nn-37f18f62d772", withExtension: "nnue")
        let big = Bundle.main.url(forResource: "nn-1111cefa1111", withExtension: "nnue")
        XCTAssertNotNil(small, "Small NNUE (nn-37f18f62d772.nnue) missing from app bundle")
        XCTAssertNotNil(big, "Big NNUE (nn-1111cefa1111.nnue) missing from app bundle")
    }

    // Single engine instance plays an opening move and then finds a forced mate.
    // We deliberately don't call stop() inside the test: Stockfish 17's
    // thread cleanup (via chesskit-engine 0.6) races and can crash the test
    // runner with libc++abi mutex errors. The cleanup-race issue is tracked
    // upstream and doesn't affect actual app usage where the engine lives
    // for the lifetime of the process.
    func testEnginePlaysOpeningAndFindsMate() async throws {
        let engine = StockfishEngine()
        await engine.start()

        // 1. Returns a legal opening move from the starting position.
        let openingMove = try await engine.bestMove(
            forFEN: ChessPosition.startFEN,
            depth: 5
        )
        let legalFirstMoves: Set<String> = [
            "a2a3", "a2a4", "b2b3", "b2b4", "c2c3", "c2c4",
            "d2d3", "d2d4", "e2e3", "e2e4", "f2f3", "f2f4",
            "g2g3", "g2g4", "h2h3", "h2h4",
            "b1a3", "b1c3", "g1f3", "g1h3"
        ]
        XCTAssertTrue(
            legalFirstMoves.contains(openingMove),
            "Expected a legal opening move, got '\(openingMove)'"
        )

        // 2. Finds Qh4# from the fool's-mate position.
        let foolsMateFEN = "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2"
        let mateMove = try await engine.bestMove(forFEN: foolsMateFEN, depth: 10)
        XCTAssertEqual(mateMove, "d8h4", "Stockfish should find Qh4# (fool's mate)")
    }
}
