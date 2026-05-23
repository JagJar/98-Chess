import ChessKitEngine
import Foundation

actor StockfishEngine: ChessEngine {
    private let engine: Engine

    init(loggingEnabled: Bool = false) {
        self.engine = Engine(type: .stockfish, loggingEnabled: loggingEnabled)
    }

    func start() async {
        await engine.start()
        while await !engine.isRunning {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func stop() async {
        await engine.stop()
    }

    func bestMove(forFEN fen: String, depth: Int) async throws -> String {
        guard let stream = await engine.responseStream else {
            throw ChessEngineError.engineNotRunning
        }

        await engine.send(command: .position(.fen(fen)))
        await engine.send(command: .go(depth: depth))

        for await response in stream {
            if case let .bestmove(move, _) = response {
                return move
            }
        }

        throw ChessEngineError.noBestMoveReturned
    }
}
