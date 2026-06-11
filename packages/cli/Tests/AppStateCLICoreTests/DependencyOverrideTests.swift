import XCTest
import AppState
@testable import AppStateCLICore

// MARK: - DependencyOverrideTests

/// Verifies that `Application.override` properly substitutes injected
/// dependencies during tests, a core AppState 3.0 capability.
final class DependencyOverrideTests: XCTestCase {

    // MARK: - Test Doubles

    /// Deterministic ID generator that counts up from "id-1".
    private final class SequentialIDGenerator: IDGenerating, @unchecked Sendable {
        private var counter = 0
        private let lock = NSLock()

        func newID() -> String {
            lock.lock()
            defer { lock.unlock() }
            counter += 1
            return "id-\(counter)"
        }
    }

    /// Clock that always returns a fixed date.
    private struct FixedClock: Clocking {
        let fixedDate: Date
        func now() -> Date { fixedDate }
    }

    // MARK: - Setup

    @MainActor
    override func setUp() async throws {
        var itemsState = Application.fileState(\.items)
        itemsState.value = []
        var counterState = Application.storedState(\.totalItemsAdded)
        counterState.value = 0
    }

    // MARK: - ID Generator Override

    @MainActor
    func testIDGeneratorOverrideProducesDeterministicIDs() async {
        let mockGenerator = SequentialIDGenerator()
        let overrideToken = Application.override(\.idGenerator, with: mockGenerator)

        _ = TaskCommands.add(title: "First item")
        _ = TaskCommands.add(title: "Second item")

        let items = Application.fileState(\.items).value ?? []
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, "id-1")
        XCTAssertEqual(items[1].id, "id-2")

        await overrideToken.cancel()
    }

    // MARK: - Clock Override

    @MainActor
    func testClockOverrideProducesExpectedTimestamp() async {
        let epoch = Date(timeIntervalSince1970: 0)
        let overrideToken = Application.override(\.clock, with: FixedClock(fixedDate: epoch))

        _ = TaskCommands.add(title: "Time-stamped item")

        let items = Application.fileState(\.items).value ?? []
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].createdAt, epoch)

        await overrideToken.cancel()
    }

    // MARK: - Override Cancellation

    @MainActor
    func testOverrideCancellationRestoresLiveDependency() async {
        let mockGenerator = SequentialIDGenerator()
        let overrideToken = Application.override(\.idGenerator, with: mockGenerator)
        await overrideToken.cancel() // Immediately restore the live UUIDGenerator.

        _ = TaskCommands.add(title: "Should get a UUID")

        let items = Application.fileState(\.items).value ?? []
        XCTAssertEqual(items.count, 1)
        // The live UUID generator produces 36-character RFC-4122 UUIDs.
        XCTAssertEqual(items[0].id.count, 36)
    }
}
