import ChessKit
import UIKit

enum Haptics {
    static func play(for move: Move, gameOver: Bool) {
        if gameOver {
            // Checkmate / stalemate / 50-move / etc. — a notification feels right.
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch move.result {
            case .capture: .medium
            case .castle:  .rigid
            case .move:    .light
            }
        }()

        UIImpactFeedbackGenerator(style: impactStyle).impactOccurred()

        if move.checkState == .check {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
}
