import SwiftUI
import AppState

// MARK: - SettingsView

/// Settings panel for adjusting timer durations and resetting session history.
///
/// All settings are `StoredState`-backed — changes persist across launches
/// without any explicit save call.
internal struct SettingsView: View {

    // MARK: AppState Observation

    @AppState(\.workMinutes) private var workMinutes: Int
    @AppState(\.breakMinutes) private var breakMinutes: Int
    @AppState(\.completedSessions) private var completedSessions: Int

    // MARK: Navigation

    @Environment(\.dismiss) private var dismiss

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(
                        value: $workMinutes,
                        in: 1...60
                    ) {
                        LabeledContent("Focus duration") {
                            Text("\(workMinutes) min")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }

                    Stepper(
                        value: $breakMinutes,
                        in: 1...30
                    ) {
                        LabeledContent("Short break") {
                            Text("\(breakMinutes) min")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("Long break") {
                        Text("\(breakMinutes * 3) min")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Timer Durations")
                } footer: {
                    Text("Long break is 3x the short break. Changes take effect on the next reset.")
                }

                Section {
                    LabeledContent("Sessions completed") {
                        Text("\(completedSessions)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        completedSessions = 0
                    } label: {
                        Label("Reset session count", systemImage: "trash")
                    }
                    .disabled(completedSessions == 0)
                } header: {
                    Text("Progress")
                } footer: {
                    Text("Session count is persisted across launches via UserDefaults.")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
