// MARK: - Board Recommendation

/// A recommendation returned by the injected board-analysis dependency.
internal struct BoardRecommendation: Sendable, Equatable {
    internal let headline: String
    internal let detail: String

    internal init(headline: String, detail: String) {
        self.headline = headline
        self.detail = detail
    }
}

// MARK: - Board Analyzing

/// An asynchronous dependency that derives the next useful action from board state.
internal protocol BoardAnalyzing: Sendable {
    func recommendation(for board: DeliveryBoard) async -> BoardRecommendation
}

// MARK: - Live Board Analyzer

/// The live, deterministic analyzer used by the example app.
internal struct LiveBoardAnalyzer: BoardAnalyzing, Sendable {
    internal init() {}

    internal func recommendation(for board: DeliveryBoard) async -> BoardRecommendation {
        await Task.yield()

        guard let nextTask = board.tasks.first(where: { !$0.isCompleted }) else {
            return BoardRecommendation(
                headline: "Ready to ship",
                detail: "Every task is complete. The workflow can move to release."
            )
        }

        return BoardRecommendation(
            headline: "Next: \(nextTask.stage.rawValue)",
            detail: nextTask.title
        )
    }
}
