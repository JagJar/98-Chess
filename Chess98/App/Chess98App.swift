import SwiftData
import SwiftUI

@main
struct Chess98App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SavedGame.self)
    }
}
