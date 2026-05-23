import SwiftUI

struct Win98Dialog<Content: View>: View {
    let title: String
    let onClose: (() -> Void)?
    @ViewBuilder var content: Content

    init(
        title: String,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { onClose?() }

            VStack(spacing: 0) {
                titleBar
                content
                    .padding(10)
            }
            .background(Win98.Palette.face)
            .win98Bevel(.outset)
            .frame(maxWidth: 320)
            .padding(.horizontal, 20)
        }
    }

    private var titleBar: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Win98.Palette.titleBarText)
                .padding(.leading, 4)
            Spacer(minLength: 0)
            if let onClose {
                Button(action: onClose) {
                    Text("✕")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Win98.Palette.text)
                        .frame(width: 16, height: 14)
                        .background(Win98.Palette.face)
                        .win98Bevel(.outset)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 2)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .background(Win98.Palette.titleBar)
    }
}
