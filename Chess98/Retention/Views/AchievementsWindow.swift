import SwiftUI

struct AchievementsWindow: View {
    let unlockedIDs: Set<String>
    let onClose: () -> Void

    var body: some View {
        Win98Dialog(title: "Achievements", onClose: onClose) {
            VStack(spacing: 6) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(AchievementCatalog.all) { ach in
                            row(for: ach)
                            Rectangle()
                                .fill(Win98.Palette.shadow.opacity(0.4))
                                .frame(height: 1)
                        }
                    }
                    .padding(2)
                }
                .frame(maxHeight: 340)
                .background(Win98.Palette.face)
                .win98Bevel(.inset)

                summary

                HStack {
                    Spacer()
                    Button("OK", action: onClose)
                        .buttonStyle(.win98)
                }
            }
            .frame(minWidth: 280)
        }
    }

    private func row(for ach: Achievement) -> some View {
        let unlocked = unlockedIDs.contains(ach.id)
        return HStack(alignment: .top, spacing: 8) {
            Text(ach.tier.stars)
                .font(.system(size: 11, weight: .bold).monospaced())
                .foregroundStyle(unlocked ? Win98.Palette.text : Win98.Palette.shadow)
                .frame(width: 36, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(ach.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(unlocked ? Win98.Palette.text : Win98.Palette.shadow)
                Text(unlocked ? ach.description : "Locked")
                    .font(.system(size: 11))
                    .foregroundStyle(Win98.Palette.shadow)
            }
            Spacer(minLength: 0)
            Text(unlocked ? "[✓]" : "[ ]")
                .font(.system(size: 11, weight: .bold).monospaced())
                .foregroundStyle(unlocked ? Win98.Palette.text : Win98.Palette.shadow)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private var summary: some View {
        let total = AchievementCatalog.all.count
        let got = unlockedIDs.intersection(Set(AchievementCatalog.all.map(\.id))).count
        return HStack {
            Text("\(got) of \(total) unlocked")
                .font(.system(size: 11))
                .foregroundStyle(Win98.Palette.text)
            Spacer()
        }
    }
}
