import SwiftUI

struct StreakBadge: View {
    let streak: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("Streak: \(streak)")
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(streak > 0 ? Win98.Palette.text : Win98.Palette.shadow)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Win98.Palette.face)
                .win98Bevel(.inset)
        }
        .buttonStyle(.plain)
    }
}
