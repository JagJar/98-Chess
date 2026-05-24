import SwiftUI

struct AchievementUnlockedDialog: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    var body: some View {
        Win98Dialog(title: "Achievement Unlocked", onClose: onDismiss) {
            VStack(spacing: 10) {
                Text(achievement.tier.stars)
                    .font(.system(size: 24, weight: .bold).monospaced())
                    .foregroundStyle(Win98.Palette.text)
                Text(achievement.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Win98.Palette.text)
                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Win98.Palette.shadow)
                    .multilineTextAlignment(.center)
                HStack {
                    Spacer()
                    Button("OK", action: onDismiss)
                        .buttonStyle(.win98)
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
        }
    }
}
