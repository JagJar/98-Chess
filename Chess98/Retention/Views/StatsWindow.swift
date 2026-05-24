import SwiftUI

struct StatsWindow: View {
    let stats: PlayerStats
    let onClose: () -> Void

    var body: some View {
        Win98Dialog(title: "Stats", onClose: onClose) {
            VStack(alignment: .leading, spacing: 8) {
                row("Games played", value: "\(stats.gamesPlayed)")
                row("Wins",         value: "\(stats.wins)")
                row("Losses",       value: "\(stats.losses)")
                row("Draws",        value: "\(stats.draws)")
                row("Win rate",     value: percentString(stats.winRate))

                Rectangle().fill(Win98.Palette.shadow).frame(height: 1).padding(.vertical, 2)

                row("Total XP",     value: "\(stats.xpTotal)")
                row("Level",        value: "\(stats.level)")
                row("Next level at", value: "\(PlayerStats.xpForLevel(stats.level + 1)) XP")

                HStack {
                    Spacer()
                    Button("OK", action: onClose)
                        .buttonStyle(.win98)
                }
                .padding(.top, 6)
            }
            .font(.system(size: 12))
            .foregroundStyle(Win98.Palette.text)
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }

    private func percentString(_ fraction: Double) -> String {
        let pct = (fraction * 100).rounded()
        return "\(Int(pct))%"
    }
}
