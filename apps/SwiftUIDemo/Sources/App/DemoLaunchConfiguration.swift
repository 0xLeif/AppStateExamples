import AppState

// MARK: - Demo Launch Configuration

/// Applies deterministic state only when UI tests explicitly opt in.
@MainActor
internal enum DemoLaunchConfiguration {
    internal static func applyIfNeeded(arguments: [String]) {
        guard arguments.contains("--ui-testing") else { return }

        var counter = Application.state(\.counter)
        counter.value = 0

        var username = Application.storedState(\.username)
        username.value = "Taylor"

        var profile = Application.fileState(\.profile)
        profile.value = nil

        var settings = Application.state(\.userSettings)
        settings.value = UserSettings()

        var board = Application.state(\.deliveryBoard)
        board.value = .sample

        var events = Application.state(\.workflowEvents)
        events.value = []

        var automation = Application.storedState(\.workflowAutomationEnabled)
        automation.value = false

        Application.reset(secureState: \.apiToken)
        Application.reset(syncState: \.theme)
        Application.dependency(\.counterService).reset()
    }
}
