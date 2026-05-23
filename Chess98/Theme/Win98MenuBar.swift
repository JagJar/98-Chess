import SwiftUI

enum Win98MenuItem: Identifiable {
    case action(id: String, label: String, action: () -> Void)
    case toggle(id: String, label: String, isOn: Bool, action: () -> Void)
    case separator(id: String)

    var id: String {
        switch self {
        case .action(let id, _, _),
             .toggle(let id, _, _, _),
             .separator(let id):
            return id
        }
    }
}

struct Win98Menu: Identifiable {
    let id: String
    let title: String
    let items: [Win98MenuItem]
}

struct Win98MenuBar: View {
    let menus: [Win98Menu]
    @Binding var openMenuID: String?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(menus) { menu in
                MenuButton(menu: menu, openMenuID: $openMenuID)
            }
            Spacer(minLength: 0)
        }
        .background(Win98.Palette.face)
    }
}

private struct MenuButton: View {
    let menu: Win98Menu
    @Binding var openMenuID: String?

    private var isOpen: Bool { openMenuID == menu.id }

    var body: some View {
        Text(menu.title)
            .font(.system(size: 12))
            .foregroundStyle(isOpen ? .white : Win98.Palette.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isOpen ? Win98.Palette.titleBar : Win98.Palette.face)
            .contentShape(Rectangle())
            .onTapGesture {
                openMenuID = isOpen ? nil : menu.id
            }
            .overlay(alignment: .topLeading) {
                if isOpen {
                    MenuDropdown(items: menu.items) { item in
                        invoke(item)
                        openMenuID = nil
                    }
                    .offset(y: 22)
                    .fixedSize()
                    .zIndex(100)
                }
            }
    }

    private func invoke(_ item: Win98MenuItem) {
        switch item {
        case .action(_, _, let action):
            action()
        case .toggle(_, _, _, let action):
            action()
        case .separator:
            break
        }
    }
}

private struct MenuDropdown: View {
    let items: [Win98MenuItem]
    let onTap: (Win98MenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                row(item)
            }
        }
        .padding(2)
        .background(Win98.Palette.face)
        .win98Bevel(.outset)
    }

    @ViewBuilder
    private func row(_ item: Win98MenuItem) -> some View {
        switch item {
        case .separator:
            Rectangle()
                .fill(Win98.Palette.shadow)
                .frame(height: 1)
                .padding(.vertical, 2)
                .padding(.horizontal, 2)
        case .action(_, let label, _):
            Button { onTap(item) } label: {
                MenuRow(label: label, check: nil)
            }
            .buttonStyle(MenuItemStyle())
        case .toggle(_, let label, let isOn, _):
            Button { onTap(item) } label: {
                MenuRow(label: label, check: isOn ? "✓" : " ")
            }
            .buttonStyle(MenuItemStyle())
        }
    }
}

private struct MenuRow: View {
    let label: String
    let check: String?

    var body: some View {
        HStack(spacing: 6) {
            if let check {
                Text(check)
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 12)
            } else {
                Spacer().frame(width: 12)
            }
            Text(label)
                .font(.system(size: 12))
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

private struct MenuItemStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .white : Win98.Palette.text)
            .background(configuration.isPressed ? Win98.Palette.titleBar : Color.clear)
    }
}
