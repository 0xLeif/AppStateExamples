import SwiftUI
import AppState

// MARK: - Profile Slice View

/// Demonstrates `@Slice` targeting individual fields of `UserSettings`,
/// and `@OptionalSlice` targeting a field inside the optional `Profile`.
///
/// Each property wrapper reaches into the composite struct and produces a
/// `Binding` to just that field — mutations leave every other field untouched.
internal struct ProfileSliceView: View {

    // MARK: @Slice — non-optional root state

    /// Directly edits `UserSettings.fontSize` without touching other fields.
    @Slice(\.userSettings, \.fontSize) private var fontSize: Double

    /// Directly edits `UserSettings.notificationsEnabled`.
    @Slice(\.userSettings, \.notificationsEnabled) private var notificationsEnabled: Bool

    /// Directly edits `UserSettings.motto`.
    @Slice(\.userSettings, \.motto) private var motto: String

    // MARK: @OptionalSlice — optional root state (FileState<Profile?>)

    /// Reaches into the optional `Profile` and exposes `displayName`.
    /// Returns `nil` when no profile has been saved yet.
    @OptionalSlice(\.profile, \.displayName) private var profileName: String?

    // MARK: Body

    internal var body: some View {
        Form {
            Section {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Stepper(
                        value: $fontSize,
                        in: 8...32,
                        step: 1
                    ) {
                        Text("\(Int(fontSize)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("FontSizeStepper")

                Toggle("Notifications Enabled", isOn: $notificationsEnabled)
                    .accessibilityIdentifier("NotificationsToggle")

                TextField("Motto", text: $motto)
                    .accessibilityIdentifier("MottoField")
            } header: {
                Text("@Slice — UserSettings (non-optional root)")
            } footer: {
                Text("Each field is an independent `@Slice` — mutating one does not re-create the whole struct.")
            }

            Section {
                if let name = profileName {
                    LabeledContent("Saved name", value: name)
                        .accessibilityIdentifier("ProfileSliceName")
                } else {
                    Text("No profile saved yet — visit Profile Editor in the State tab first.")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            } header: {
                Text("@OptionalSlice — Profile.displayName (optional root)")
            } footer: {
                Text(
                    "`@OptionalSlice` returns `nil` when the root optional state has no value — "
                        + "no crash, no force-unwrap."
                )
            }

            Section("Full UserSettings snapshot") {
                LabeledContent("fontSize", value: "\(Int(fontSize)) pt")
                    .accessibilityIdentifier("SliceFontSizeValue")
                LabeledContent("notificationsEnabled", value: notificationsEnabled ? "true" : "false")
                    .accessibilityIdentifier("SliceNotificationsValue")
                LabeledContent("motto", value: motto.isEmpty ? "(empty)" : motto)
                    .accessibilityIdentifier("SliceMottoValue")
            }
        }
        .navigationTitle("Slices")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
