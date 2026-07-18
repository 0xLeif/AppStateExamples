import SwiftUI
import XCTest
import AppState
import SnapshotTesting
@testable import SwiftUIDemo

// MARK: - Catalog Snapshot Tests

/// Image-regression coverage for deterministic SwiftUI states.
@MainActor
internal final class CatalogSnapshotTests: XCTestCase {
    internal func testWorkflowInitialState() {
        seed(board: .sample, events: [])
        assertSnapshot(
            of: WorkflowView(),
            as: .image(
                layout: .fixed(width: 390, height: 844),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: "workflow-initial",
            record: .missing
        )
    }

    internal func testWorkflowProgressState() {
        seed(
            board: .snapshotProgress,
            events: [
                WorkflowEvent(id: "snapshot", message: "Completed: Record visual snapshots"),
                WorkflowEvent(id: "state", message: "Completed: Build integrated state flow")
            ]
        )

        assertSnapshot(
            of: WorkflowView(),
            as: .image(
                layout: .fixed(width: 390, height: 844),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: "workflow-progress",
            record: .missing
        )
    }

    internal func testStateCatalogDarkMode() {
        seed(board: .sample, events: [])
        assertSnapshot(
            of: StateSection(),
            as: .image(
                layout: .fixed(width: 390, height: 844),
                traits: UITraitCollection(userInterfaceStyle: .dark)
            ),
            named: "state-catalog-dark",
            record: .missing
        )
    }

    internal func testUsernameScreen() {
        var username = Application.storedState(\.username)
        username.value = "Taylor"
        assertCatalogSnapshot(of: UsernameView(), named: "username-stored-state")
    }

    internal func testProfileEditorScreen() {
        var profile = Application.fileState(\.profile)
        profile.value = Profile(displayName: "Morgan", bio: "Ships reliable Swift apps")
        assertCatalogSnapshot(of: ProfileEditorView(), named: "profile-file-state")
    }

    internal func testSliceEditorScreen() {
        var settings = Application.state(\.userSettings)
        settings.value = UserSettings(fontSize: 18, notificationsEnabled: false, motto: "State with confidence")
        var profile = Application.fileState(\.profile)
        profile.value = Profile(displayName: "Morgan", bio: "")
        assertCatalogSnapshot(of: ProfileSliceView(), named: "profile-slices")
    }

    internal func testObservedDependencyScreen() {
        let service = Application.dependency(\.counterService)
        service.reset()
        service.tick()
        service.tick()
        assertCatalogSnapshot(of: ObservedCounterView(), named: "observed-dependency")
    }

    internal func testSecureStateScreen() {
        Application.reset(secureState: \.apiToken)
        assertCatalogSnapshot(of: SecureTokenView(), named: "secure-state")
    }

    internal func testSyncStateScreen() {
        var theme = Application.syncState(\.theme)
        theme.value = "light"
        assertCatalogSnapshot(of: ThemeToggleView(), named: "sync-state")
    }

    internal func testDependenciesCatalogScreen() {
        assertCatalogSnapshot(of: DependenciesSection(), named: "dependencies-catalog")
    }

    private func assertCatalogSnapshot<Content: View>(of view: Content, named name: String) {
        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 390, height: 844),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: name,
            record: .missing
        )
    }

    private func seed(board: DeliveryBoard, events: [WorkflowEvent]) {
        var boardState = Application.state(\.deliveryBoard)
        boardState.value = board

        var eventState = Application.state(\.workflowEvents)
        eventState.value = events

        var automationState = Application.storedState(\.workflowAutomationEnabled)
        automationState.value = true
    }
}
