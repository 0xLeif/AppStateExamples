import SwiftUI
import AppState

// MARK: - DependencySectionView

/// Demonstrates `@AppDependency` and `Application.override`.
///
/// The `GreetingProviding` service composes the stored greeting for display.
/// A button hot-swaps the live implementation for a mock, and the returned
/// `Application.DependencyOverride` token cancels the swap when tapped again.
/// `token.cancel()` is `async` so it is wrapped in a `Task`.
internal struct DependencySectionView: View {

    // MARK: Dependencies

    @AppDependency(\.greetingService) private var greetingService: any GreetingProviding

    // MARK: State

    @StoredState(\.greeting) private var greeting: String

    /// Holds the live override token; `nil` means the live service is active.
    @State private var overrideToken: Application.DependencyOverride? = nil

    // MARK: Body

    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(
                title: "@AppDependency",
                subtitle: "Inject & hot-swap services via Application.override"
            )

            Text(greetingService.compose(from: greeting))
                .font(.body.italic())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

            HStack {
                activeServiceBadge
                Spacer()
                overrideButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Private Views

    @ViewBuilder
    private var activeServiceBadge: some View {
        Label(
            overrideToken != nil ? "MockGreetingService" : "LiveGreetingService",
            systemImage: overrideToken != nil ? "wrench.and.screwdriver.fill" : "checkmark.seal.fill"
        )
        .font(.caption)
        .foregroundStyle(overrideToken != nil ? .orange : .green)
    }

    @ViewBuilder
    private var overrideButton: some View {
        if overrideToken == nil {
            Button("Use Mock") {
                overrideToken = Application.override(
                    \.greetingService,
                    with: MockGreetingService()
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } else {
            Button("Restore Live") {
                Task { @MainActor in
                    await overrideToken?.cancel()
                    overrideToken = nil
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundStyle(.red)
        }
    }
}
