import SwiftUI

enum OnboardingStep {
    case welcome
    case dailyReminder
}

/// Three-step onboarding flow: a welcome dialog, a daily-reminder pre-prompt
/// with time picker, and (only if the user opts in) the system permission
/// prompt. We never re-show this — `onboardingCompleted` is set after step 2.
struct OnboardingWelcomeDialog: View {
    let onNext: () -> Void

    var body: some View {
        Win98Dialog(title: "Welcome to Chess 98", onClose: onNext) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to Chess 98.")
                    .font(.system(size: 14, weight: .bold))
                Text("Play daily to build a streak and earn XP. Unlock achievements as you beat tougher opponents and solve daily puzzles.")
                HStack {
                    Spacer()
                    Button("Next", action: onNext)
                        .buttonStyle(.win98)
                }
                .padding(.top, 4)
            }
            .font(.system(size: 12))
            .foregroundStyle(Win98.Palette.text)
        }
    }
}

struct OnboardingDailyReminderDialog: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        Win98Dialog(title: "Daily Reminder", onClose: onNo) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Want a daily reminder to play?")
                    .font(.system(size: 13, weight: .semibold))
                Text("You can change the time or turn it off later in Tools › Notifications.")
                    .foregroundStyle(Win98.Palette.shadow)
                ReminderTimePicker(hour: $hour, minute: $minute)
                HStack(spacing: 6) {
                    Spacer()
                    Button("No thanks", action: onNo)
                        .buttonStyle(.win98)
                    Button("Yes, remind me", action: onYes)
                        .buttonStyle(.win98)
                }
                .padding(.top, 6)
            }
            .font(.system(size: 12))
            .foregroundStyle(Win98.Palette.text)
        }
    }
}

struct ReminderTimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        DatePicker(
            "Time",
            selection: Binding(
                get: {
                    var comps = DateComponents()
                    comps.hour = hour
                    comps.minute = minute
                    return Calendar.current.date(from: comps) ?? .now
                },
                set: { newValue in
                    let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    hour = c.hour ?? 19
                    minute = c.minute ?? 0
                }
            ),
            displayedComponents: .hourAndMinute
        )
        .labelsHidden()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Win98.Palette.face)
        .win98Bevel(.inset)
    }
}
