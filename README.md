# 98 Chess

A Windows 98 themed chess app for iOS. Play against the computer in a faithful recreation of the classic desktop aesthetic.

## Status

Pre-alpha. Under active development.

## Requirements

- iOS 17 or later
- Xcode 16 or later (to build from source)

## Building

Open `98Chess.xcodeproj` in Xcode and run on the iOS Simulator or a connected device.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

This project bundles [Stockfish](https://stockfishchess.org/) 17 (GPL v3) as its chess engine, along with the two NNUE evaluation networks (`nn-1111cefa1111.nnue` and `nn-37f18f62d772.nnue`) published by the Stockfish project under the same license.
