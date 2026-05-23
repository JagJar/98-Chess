import SwiftUI

struct Win98Window<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            content
                .padding(Win98.Metrics.windowPadding)
        }
        .background(Win98.Palette.face)
        .win98Bevel(.outset)
    }

    private var titleBar: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Win98.Palette.titleBarText)
                .padding(.leading, 4)
            Spacer(minLength: 0)
            // Decorative window controls (non-functional for now)
            ForEach(["_", "□", "✕"], id: \.self) { glyph in
                Text(glyph)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Win98.Palette.text)
                    .frame(width: 16, height: 14)
                    .background(Win98.Palette.face)
                    .win98Bevel(.outset)
                    .padding(.trailing, 2)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .background(Win98.Palette.titleBar)
    }
}
