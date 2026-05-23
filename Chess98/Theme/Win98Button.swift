import SwiftUI

struct Win98ButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .foregroundStyle(isEnabled ? Win98.Palette.text : Win98.Palette.shadow)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(minWidth: 70)
            .background(Win98.Palette.face)
            .win98Bevel(configuration.isPressed ? .inset : .outset)
            .contentShape(Rectangle())
    }

    @Environment(\.isEnabled) private var isEnabled: Bool
}

extension ButtonStyle where Self == Win98ButtonStyle {
    static var win98: Win98ButtonStyle { Win98ButtonStyle() }
}
