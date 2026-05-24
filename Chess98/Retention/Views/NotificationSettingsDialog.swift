import SwiftUI
import UIKit
import UserNotifications

struct NotificationSettingsDialog: View {
    @Binding var enabled: Bool
    @Binding var hour: Int
    @Binding var minute: Int
    let authorizationStatus: UNAuthorizationStatus
    let onClose: () -> Void
    let onCommit: () -> Void

    var body: some View {
        Win98Dialog(title: "Notifications", onClose: onClose) {
            VStack(alignment: .leading, spacing: 10) {
                if authorizationStatus == .denied {
                    Text("Notifications are turned off in iOS Settings.")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Open Settings to enable them, then come back.")
                        .foregroundStyle(Win98.Palette.shadow)
                    HStack {
                        Spacer()
                        Button("Open Settings", action: openSettings)
                            .buttonStyle(.win98)
                        Button("OK", action: onClose)
                            .buttonStyle(.win98)
                    }
                } else {
                    Button(action: {
                        enabled.toggle()
                        onCommit()
                    }) {
                        HStack(spacing: 6) {
                            Text(enabled ? "[✓]" : "[ ]")
                                .font(.system(size: 12, weight: .bold).monospaced())
                            Text("Daily reminder")
                                .font(.system(size: 12))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Win98.Palette.text)

                    if enabled {
                        ReminderTimePicker(hour: $hour, minute: $minute)
                            .onChange(of: hour) { _, _ in onCommit() }
                            .onChange(of: minute) { _, _ in onCommit() }
                    }

                    HStack {
                        Spacer()
                        Button("OK", action: onClose)
                            .buttonStyle(.win98)
                    }
                    .padding(.top, 6)
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(Win98.Palette.text)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
