import SwiftUI
import AppState

// MARK: - Workflow View

/// A cohesive scenario combining state, persistence, derived values, async DI, and collection mutations.
internal struct WorkflowView: View {
    @AppState(\.deliveryBoard) private var board: DeliveryBoard
    @AppState(\.workflowEvents) private var events: [WorkflowEvent]
    @StoredState(\.workflowAutomationEnabled) private var automationEnabled: Bool
    @AppDependency(\.boardAnalyzer) private var analyzer: any BoardAnalyzing

    @State private var recommendation: BoardRecommendation? = nil
    @State private var isAnalyzing: Bool = false

    internal var body: some View {
        NavigationStack {
            List {
                progressSection
                controlsSection
                tasksSection
                activitySection
            }
            .navigationTitle("Delivery Workflow")
            .accessibilityIdentifier("WorkflowScreen")
        }
    }

    private var progressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("AppState 3 rollout", systemImage: "shippingbox.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(board.completedCount)/\(board.tasks.count)")
                        .monospacedDigit()
                        .accessibilityIdentifier("WorkflowProgressCount")
                }

                Text("\(events.count) activity events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("WorkflowEventCount")

                ProgressView(value: board.completionFraction)
                    .tint(.indigo)

                Text("In-memory collection state drives this summary, every task row, and the timeline below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var controlsSection: some View {
        Section {
            Toggle("Auto-analyze after changes", isOn: $automationEnabled)
                .accessibilityIdentifier("WorkflowAutomationToggle")

            Button {
                Task { await analyzeBoard() }
            } label: {
                Label(isAnalyzing ? "Analyzing…" : "Analyze Next Step", systemImage: "sparkles")
            }
            .disabled(isAnalyzing)
            .accessibilityIdentifier("AnalyzeWorkflowButton")

            if let recommendation {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.headline)
                        .font(.headline)
                        .accessibilityIdentifier("WorkflowRecommendationHeadline")
                    Text(recommendation.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Reset Workflow", role: .destructive) {
                board = .sample
                events = []
                recommendation = nil
            }
            .accessibilityIdentifier("ResetWorkflowButton")
        } header: {
            Text("Stored preference + async dependency")
        }
    }

    private var tasksSection: some View {
        Section("Tasks") {
            ForEach(board.tasks) { task in
                Button {
                    toggle(task)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? .green : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .foregroundStyle(.primary)
                                .strikethrough(task.isCompleted)
                            Text(task.stage.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("WorkflowTask-\(task.id)")
                .accessibilityValue(task.isCompleted ? "Complete" : "Incomplete")
            }
        }
    }

    private var activitySection: some View {
        Section("Activity timeline") {
            if events.isEmpty {
                Text("Complete a task to create a cross-state activity event.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("WorkflowEmptyActivity")
            } else {
                ForEach(events) { event in
                    Label(event.message, systemImage: "bolt.horizontal.circle")
                        .font(.subheadline)
                        .accessibilityIdentifier("WorkflowEvent")
                }
            }
        }
    }

    private func toggle(_ task: DeliveryTask) {
        let wasCompleted = task.isCompleted
        board = board.togglingTask(id: task.id)

        let action = wasCompleted ? "Reopened" : "Completed"
        let event = WorkflowEvent(id: "\(task.id)-\(events.count)", message: "\(action): \(task.title)")
        events = Array(([event] + events).prefix(6))

        guard automationEnabled else { return }
        Task { await analyzeBoard() }
    }

    @MainActor
    private func analyzeBoard() async {
        isAnalyzing = true
        recommendation = await analyzer.recommendation(for: board)
        isAnalyzing = false
    }
}
