import XCTest
import AppState
@testable import SwiftUIDemo

// MARK: - Core Behavior Tests

/// Fast unit coverage for model branches that UI and image tests should not need to infer.
@MainActor
internal final class CoreBehaviorTests: XCTestCase {
    internal func testDeliveryBoardCountsProgressAndTogglesKnownTask() {
        let empty = DeliveryBoard(tasks: [])
        XCTAssertEqual(empty.completedCount, 0)
        XCTAssertEqual(empty.completionFraction, 0)

        let toggled = DeliveryBoard.sample.togglingTask(id: "map")
        XCTAssertEqual(toggled.completedCount, 1)
        XCTAssertEqual(toggled.completionFraction, 0.2, accuracy: 0.001)
        XCTAssertTrue(toggled.tasks.first?.isCompleted == true)
        XCTAssertEqual(toggled.togglingTask(id: "map"), .sample)
    }

    internal func testDeliveryBoardIgnoresUnknownTask() {
        XCTAssertEqual(DeliveryBoard.sample.togglingTask(id: "missing"), .sample)
        XCTAssertEqual(DeliveryStage.allCases.map(\.rawValue), ["Plan", "Build", "Verify", "Ship"])
    }

    internal func testAnalyzerRecommendsNextTaskAndReadyToShip() async {
        let analyzer = LiveBoardAnalyzer()
        let next = await analyzer.recommendation(for: .sample)
        XCTAssertEqual(next, BoardRecommendation(headline: "Next: Plan", detail: "Map AppState 3 APIs"))

        let completed = DeliveryBoard(
            tasks: DeliveryBoard.sample.tasks.map { task in
                DeliveryTask(id: task.id, title: task.title, stage: task.stage, isCompleted: true)
            }
        )
        let ready = await analyzer.recommendation(for: completed)
        XCTAssertEqual(ready.headline, "Ready to ship")
        XCTAssertTrue(ready.detail.contains("Every task is complete"))
    }

    internal func testGreetingServicesCoverNamedAndEmptyInputs() {
        let live = LiveGreetingService()
        let mock = MockGreetingService()

        XCTAssertEqual(live.greet("Taylor"), "Hello, Taylor! 👋")
        XCTAssertEqual(live.greet(""), "Hello, World! 👋")
        XCTAssertEqual(mock.greet("Taylor"), "[MOCK] Greetings, Taylor!")
        XCTAssertEqual(mock.greet(""), "[MOCK] Greetings, stranger!")
    }

    internal func testObservableCounterTicksAndResets() {
        let service = LiveCounterService()
        XCTAssertEqual(service.ticks, 0)
        service.tick()
        service.tick()
        XCTAssertEqual(service.ticks, 2)
        service.reset()
        XCTAssertEqual(service.ticks, 0)
    }

    internal func testApplicationStateAccessorsRoundTripValues() {
        var counter = Application.state(\.counter)
        counter.value = 9
        XCTAssertEqual(Application.state(\.counter).value, 9)

        var settings = Application.state(\.userSettings)
        settings.value = UserSettings(fontSize: 20, notificationsEnabled: false, motto: "Test")
        XCTAssertEqual(Application.state(\.userSettings).value.fontSize, 20)

        var events = Application.state(\.workflowEvents)
        events.value = [WorkflowEvent(id: "test", message: "Covered")]
        XCTAssertEqual(Application.state(\.workflowEvents).value.first?.message, "Covered")
    }

    internal func testDependencyOverrideRestoresLiveService() async {
        XCTAssertTrue(Application.dependency(\.greetingService) is LiveGreetingService)
        let override = Application.override(\.greetingService, with: MockGreetingService())
        XCTAssertTrue(Application.dependency(\.greetingService) is MockGreetingService)
        await override.cancel()
        XCTAssertTrue(Application.dependency(\.greetingService) is LiveGreetingService)
    }
}
