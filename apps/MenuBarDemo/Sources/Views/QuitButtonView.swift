import SwiftUI
import AppKit

// MARK: - QuitButtonView

/// A menu-bar-style quit button that terminates the app cleanly.
internal struct QuitButtonView: View {

    // MARK: Body

    internal var body: some View {
        HStack {
            Spacer()
            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit MenuBarDemo", systemImage: "power")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            Spacer()
        }
    }
}
