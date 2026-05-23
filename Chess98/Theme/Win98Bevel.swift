import SwiftUI

struct Win98Bevel: ViewModifier {
    enum Style { case outset, inset }
    let style: Style

    func body(content: Content) -> some View {
        content
            // OUTER ring (1px)
            .overlay(alignment: .top)      { edge(width: nil,  height: 1, color: outerLight) }
            .overlay(alignment: .leading)  { edge(width: 1,    height: nil, color: outerLight) }
            .overlay(alignment: .bottom)   { edge(width: nil,  height: 1, color: outerDark) }
            .overlay(alignment: .trailing) { edge(width: 1,    height: nil, color: outerDark) }
            // INNER ring (1px, inset by 1)
            .overlay(alignment: .top) {
                Rectangle().fill(innerLight)
                    .frame(height: 1)
                    .padding(.horizontal, 1)
                    .padding(.top, 1)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .leading) {
                Rectangle().fill(innerLight)
                    .frame(width: 1)
                    .padding(.vertical, 1)
                    .padding(.leading, 1)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(innerDark)
                    .frame(height: 1)
                    .padding(.horizontal, 1)
                    .padding(.bottom, 1)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .trailing) {
                Rectangle().fill(innerDark)
                    .frame(width: 1)
                    .padding(.vertical, 1)
                    .padding(.trailing, 1)
                    .allowsHitTesting(false)
            }
    }

    @ViewBuilder
    private func edge(width: CGFloat?, height: CGFloat?, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
            .allowsHitTesting(false)
    }

    private var outerLight: Color { style == .outset ? Win98.Palette.highlight : Win98.Palette.darkShadow }
    private var outerDark:  Color { style == .outset ? Win98.Palette.darkShadow : Win98.Palette.highlight }
    private var innerLight: Color { style == .outset ? Win98.Palette.light : Win98.Palette.shadow }
    private var innerDark:  Color { style == .outset ? Win98.Palette.shadow : Win98.Palette.light }
}

extension View {
    func win98Bevel(_ style: Win98Bevel.Style = .outset) -> some View {
        modifier(Win98Bevel(style: style))
    }
}
