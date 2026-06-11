#if canImport(SwiftData)
import SwiftUI

// MARK: - SwiftData Section

/// Demonstrates `@ModelState` — a SwiftData-backed list of `TodoItem` models
/// with lenient and strict insert, delete, and list operations.
internal struct SwiftDataSection: View {

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            TodoListView()
        }
    }
}
#endif
