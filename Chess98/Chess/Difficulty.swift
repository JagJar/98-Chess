import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case beginner, easy, medium, hard, master

    var id: String { rawValue }

    var label: String {
        switch self {
        case .beginner: "Beginner"
        case .easy:     "Easy"
        case .medium:   "Medium"
        case .hard:     "Hard"
        case .master:   "Master"
        }
    }

    var skillLevel: Int {
        switch self {
        case .beginner: 0
        case .easy:     5
        case .medium:   10
        case .hard:     15
        case .master:   20
        }
    }

    var depth: Int {
        switch self {
        case .beginner: 3
        case .easy:     5
        case .medium:   8
        case .hard:     12
        case .master:   15
        }
    }
}
