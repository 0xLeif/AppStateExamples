import SwiftUI

// MARK: - SessionBadgeView

/// A compact badge showing the number of completed focus sessions.
///
/// Uses filled tomato symbols to give a tactile sense of progress through the day.
internal struct SessionBadgeView: View {

    // MARK: Properties

    internal let completedSessions: Int

    // MARK: Body

    internal var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(sessionLabel)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: Private

    private var sessionLabel: String {
        completedSessions == 1 ? "1 session" : "\(completedSessions) sessions"
    }
}
