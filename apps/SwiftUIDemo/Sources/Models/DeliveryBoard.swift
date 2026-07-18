import Foundation

// MARK: - Delivery Stage

/// The lifecycle stages used by the integrated delivery-board example.
internal enum DeliveryStage: String, CaseIterable, Codable, Sendable, Equatable {
    case plan = "Plan"
    case build = "Build"
    case verify = "Verify"
    case ship = "Ship"
}

// MARK: - Delivery Task

/// A deterministic task in the delivery-board example.
internal struct DeliveryTask: Identifiable, Codable, Sendable, Equatable {
    internal let id: String
    internal let title: String
    internal let stage: DeliveryStage
    internal var isCompleted: Bool

    internal init(id: String, title: String, stage: DeliveryStage, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.stage = stage
        self.isCompleted = isCompleted
    }
}

// MARK: - Delivery Board

/// Composite in-memory state used to demonstrate realistic AppState mutations.
internal struct DeliveryBoard: Codable, Sendable, Equatable {
    internal var tasks: [DeliveryTask]

    internal var completedCount: Int {
        tasks.count(where: \.isCompleted)
    }

    internal var completionFraction: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    internal static let sample: DeliveryBoard = DeliveryBoard(tasks: [
        DeliveryTask(id: "map", title: "Map AppState 3 APIs", stage: .plan),
        DeliveryTask(id: "state", title: "Build integrated state flow", stage: .build),
        DeliveryTask(id: "snapshots", title: "Record visual snapshots", stage: .verify),
        DeliveryTask(id: "ui-tests", title: "Run the UI journey", stage: .verify),
        DeliveryTask(id: "release", title: "Ship the stable example", stage: .ship)
    ])

    internal static let snapshotProgress: DeliveryBoard = DeliveryBoard(tasks: [
        DeliveryTask(id: "map", title: "Map AppState 3 APIs", stage: .plan, isCompleted: true),
        DeliveryTask(id: "state", title: "Build integrated state flow", stage: .build, isCompleted: true),
        DeliveryTask(id: "snapshots", title: "Record visual snapshots", stage: .verify, isCompleted: true),
        DeliveryTask(id: "ui-tests", title: "Run the UI journey", stage: .verify),
        DeliveryTask(id: "release", title: "Ship the stable example", stage: .ship)
    ])

    internal func togglingTask(id: String) -> DeliveryBoard {
        var updatedTasks = tasks
        guard let index = updatedTasks.firstIndex(where: { $0.id == id }) else { return self }
        updatedTasks[index].isCompleted.toggle()
        return DeliveryBoard(tasks: updatedTasks)
    }
}

// MARK: - Workflow Event

/// A bounded activity entry stored in AppState alongside the board.
internal struct WorkflowEvent: Identifiable, Codable, Sendable, Equatable {
    internal let id: String
    internal let message: String

    internal init(id: String, message: String) {
        self.id = id
        self.message = message
    }
}
