import SwiftUI
import AppState

// MARK: - AccentSyncSectionView

/// Demonstrates `@SyncState` — a `String` synchronised across devices via iCloud KV.
///
/// Selecting a different accent propagates to all signed-in devices via
/// `NSUbiquitousKeyValueStore`. A valid iCloud-capable signing configuration is
/// required for cross-device sync to function. Without the ubiquity KV entitlement
/// (e.g. local ad-hoc builds), `MenuBarDemoApp` installs a local fallback at launch
/// so the value is stored and read locally via `UserDefaults` instead of crashing.
internal struct AccentSyncSectionView: View {

    // MARK: Constants

    /// Available accent name choices shown in the Picker.
    private static let accentOptions: [String] = [
        "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Teal"
    ]

    // MARK: State

    @SyncState(\.accentName) private var accentName: String

    // MARK: Body

    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(
                title: "@SyncState",
                subtitle: Application.hasUbiquityKVStoreEntitlement
                    ? "iCloud KV — synced across all signed-in devices"
                    : "Local fallback — no iCloud KV entitlement"
            )

            Picker("Accent", selection: $accentName) {
                ForEach(Self.accentOptions, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 6) {
                accentSwatch
                Text("iCloud value: \"\(accentName)\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Private Views

    @ViewBuilder
    private var accentSwatch: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color(for: accentName))
            .frame(width: 14, height: 14)
    }

    // MARK: Private Helpers

    private func color(for name: String) -> Color {
        switch name {
        case "Blue":   return .blue
        case "Purple": return .purple
        case "Pink":   return .pink
        case "Red":    return .red
        case "Orange": return .orange
        case "Yellow": return .yellow
        case "Green":  return .green
        case "Teal":   return .teal
        default:       return .accentColor
        }
    }
}
