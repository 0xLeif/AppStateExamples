import SwiftUI

// MARK: - Root Catalog View

/// Tab-based catalog that organises every AppState 3.0 demo section.
internal struct RootCatalogView: View {

    // MARK: Body

    internal var body: some View {
        TabView {
            StateSection()
                .tabItem {
                    Label("State", systemImage: "square.stack.3d.up")
                }

            WorkflowView()
                .tabItem {
                    Label("Workflow", systemImage: "point.3.connected.trianglepath.dotted")
                }

            DependenciesSection()
                .tabItem {
                    Label("Dependencies", systemImage: "arrow.triangle.branch")
                }

            #if canImport(SwiftData)
            SwiftDataSection()
                .tabItem {
                    Label("SwiftData", systemImage: "cylinder.split.1x2")
                }
            #endif

            ObservabilitySection()
                .tabItem {
                    Label("Observability", systemImage: "eye")
                }
        }
        .accessibilityIdentifier("RootTabView")
    }
}
