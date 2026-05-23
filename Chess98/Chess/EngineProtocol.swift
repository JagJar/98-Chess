import Foundation

protocol ChessEngine: Sendable {
    func start() async
    func stop() async
    func bestMove(forFEN fen: String, depth: Int) async throws -> String
}

enum ChessEngineError: Error {
    case engineNotRunning
    case noBestMoveReturned
}

enum ChessPosition {
    static let startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
}
