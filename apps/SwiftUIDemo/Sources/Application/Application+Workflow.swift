import AppState

// MARK: - Application Workflow Extensions

extension Application {
    /// A composite collection state used by the integrated workflow example.
    internal var deliveryBoard: State<DeliveryBoard> {
        state(initial: .sample, id: "deliveryBoard")
    }

    /// A bounded activity timeline updated alongside the delivery board.
    internal var workflowEvents: State<[WorkflowEvent]> {
        state(initial: [], id: "workflowEvents")
    }

    /// A persisted preference proving stored and in-memory state can cooperate.
    internal var workflowAutomationEnabled: StoredState<Bool> {
        storedState(initial: true, id: "workflowAutomationEnabled")
    }

    /// The async analyzer resolved by `WorkflowView` through dependency injection.
    internal var boardAnalyzer: Dependency<any BoardAnalyzing> {
        dependency(LiveBoardAnalyzer(), id: "boardAnalyzer")
    }
}
