import SwiftUI

struct ReminderCard: View {
    @Bindable var reminderManager: ReminderManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.orange)
                Text("Reading Reminder")
                    .font(.headline)
                Spacer()
            }

            if !reminderManager.isAuthorized {
                VStack(spacing: 8) {
                    Text("Get a daily nudge to keep your reading habit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await reminderManager.requestAccess() }
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.badge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } else {
                Toggle(isOn: Binding(
                    get: { reminderManager.reminderEnabled },
                    set: { reminderManager.reminderEnabled = $0 }
                )) {
                    Text("Daily Reminder")
                        .font(.subheadline)
                }

                if reminderManager.reminderEnabled {
                    DatePicker(
                        "Remind at",
                        selection: Binding(
                            get: {
                                var comps = DateComponents()
                                comps.hour = reminderManager.reminderHour
                                comps.minute = reminderManager.reminderMinute
                                return Calendar.current.date(from: comps) ?? Date()
                            },
                            set: { date in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                reminderManager.reminderHour = comps.hour ?? 21
                                reminderManager.reminderMinute = comps.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .font(.subheadline)
                }

                Divider()

                Toggle(isOn: Binding(
                    get: { reminderManager.weeklySummaryEnabled },
                    set: { reminderManager.weeklySummaryEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Summary")
                            .font(.subheadline)
                        Text("Sunday at 10 AM")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
