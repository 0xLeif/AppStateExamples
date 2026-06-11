import SwiftUI
import AppState

// MARK: - Profile Editor View

/// Demonstrates `@FileState` with a `Codable` struct.
/// The profile is written to and loaded from the app-sandbox file system.
internal struct ProfileEditorView: View {

    // MARK: State

    @FileState(\.profile) private var profile: Profile?

    /// Drives the display name text field, synced to `profile.displayName`.
    @State private var displayNameDraft: String = ""

    /// Drives the bio text editor, synced to `profile.bio`.
    @State private var bioDraft: String = ""

    // MARK: Body

    internal var body: some View {
        Form {
            Section("Display Name") {
                TextField("Display name", text: $displayNameDraft)
                    .accessibilityIdentifier("ProfileDisplayNameField")
            }

            Section("Bio") {
                TextField("Short bio", text: $bioDraft, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityIdentifier("ProfileBioField")
            }

            Section {
                Button("Save Profile") {
                    saveProfile()
                }
                .accessibilityIdentifier("SaveProfileButton")

                if profile != nil {
                    Button("Delete Profile", role: .destructive) {
                        profile = nil
                        displayNameDraft = ""
                        bioDraft = ""
                    }
                }
            }

            if let savedProfile = profile {
                Section("Saved on Disk") {
                    LabeledContent("Name", value: savedProfile.displayName)
                    LabeledContent("Bio", value: savedProfile.bio.isEmpty ? "(empty)" : savedProfile.bio)
                }
            }
        }
        .navigationTitle("Profile (@FileState)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            displayNameDraft = profile?.displayName ?? ""
            bioDraft = profile?.bio ?? ""
        }
    }

    // MARK: Private Methods

    private func saveProfile() {
        profile = Profile(
            displayName: displayNameDraft,
            bio: bioDraft
        )
    }
}
