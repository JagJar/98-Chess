# 98 Chess

A Windows 98 themed chess app for iOS. Play against the computer in a faithful recreation of the classic desktop aesthetic — teal background, gray window chrome, navy title bar, and a Stockfish-powered opponent.

## Status

v0.1.0 — feature-complete for first release. Pending App Store submission.

## Features

- Five difficulty levels (Beginner / Easy / Medium / Hard / Master) backed by Stockfish 17
- Full chess rules: castling, en passant, promotion (with a Win98-style picker), draw by stalemate, fifty-move rule, threefold repetition, insufficient material
- Game state persists across launches via SwiftData
- Adaptive layout — iPhone portrait stacks board + history; iPhone landscape and iPad show them side by side
- Haptic feedback on every move (light / medium / rigid / heavy mapped to move, capture, castle, check)
- VoiceOver labels on every square and menu item

## Requirements

- iOS 17 or later
- Xcode 16 or later (to build from source)

## Building

```sh
xcodegen generate   # if you edit project.yml; otherwise just open the project
open Chess98.xcodeproj
```

Then run the `Chess98` scheme on a simulator or device.

## Privacy

98 Chess does not collect, transmit, or share any personal information. All game state lives on-device in the app's own SwiftData store. The app makes no network requests. The bundled privacy manifest declares one Required Reason API use — `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1) — for storing the difficulty preference.

## Attribution

This project bundles or depends on the following open-source software:

- [Stockfish 17](https://stockfishchess.org/) — chess engine, GPL v3
- Stockfish NNUE networks `nn-1111cefa1111.nnue` and `nn-37f18f62d772.nnue` — GPL v3
- [chesskit-swift](https://github.com/chesskit-app/chesskit-swift) — chess logic, MIT
- [chesskit-engine](https://github.com/chesskit-app/chesskit-engine) — UCI wrapper for Stockfish, MIT

## License

GPL-3.0-or-later. See [LICENSE](LICENSE). The app is open-sourced because Stockfish (statically linked) is GPL v3.
