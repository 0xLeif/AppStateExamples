import SwiftUI
import AppState

// MARK: - Observability Section

/// Demonstrates AppState 3.0's headline feature: headless observation via
/// `withObservationTracking` alongside the same counter driven from a SwiftUI button.
///
/// A `HeadlessObserver` instance lives here as `@State` — it receives change
/// callbacks from `Application.counter` without being inside a SwiftUI body.
/// The log it produces proves the observation fired outside SwiftUI.
internal struct ObservabilitySection: View {

    // MARK: State

    @AppState(\.counter) private var counter: Int

    @State private var observer: HeadlessObserver = HeadlessObserver()

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            Form {
                counterSection
                observerSection
                logSection
            }
            .navigationTitle("Observability")
            .onAppear {
                observer.startObserving()
            }
            .onDisappear {
                observer.stopObserving()
            }
        }
    }

    // MARK: Private Views

    private var counterSection: some View {
        Section {
            Stepper(
                value: $counter,
                in: Int.min...Int.max
            ) {
                HStack {
                    Text("counter")
                    Spacer()
                    Text("\(counter)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("ObservabilityCounterValue")
                }
            }
            .accessibilityIdentifier("ObservabilityCounterStepper")

            Button("Reset to 0") {
                counter = 0
            }
            .foregroundStyle(.red)
        } header: {
            Text("Counter (@AppState)")
        } footer: {
            Text("The same `Application.counter` as in the State tab — mutate it here or there; the headless observer below reacts either way.")
        }
    }

    private var observerSection: some View {
        Section {
            LabeledContent("Status") {
                HStack(spacing: 6) {
                    Circle()
                        .fill(observer.isObserving ? .green : .secondary)
                        .frame(width: 8, height: 8)
                    Text(observer.isObserving ? "Observing" : "Stopped")
                        .foregroundStyle(observer.isObserving ? .primary : .secondary)
                        .accessibilityIdentifier("ObserverStatus")
                }
            }

            LabeledContent("Events captured", value: "\(observer.log.count)")
                .accessibilityIdentifier("ObserverEventCount")

            Button(observer.isObserving ? "Stop Observing" : "Start Observing") {
                if observer.isObserving {
                    observer.stopObserving()
                } else {
                    observer.startObserving()
                }
            }
            .accessibilityIdentifier("ToggleObserverButton")
        } header: {
            Text("Headless Observer")
        } footer: {
            Text("`HeadlessObserver` is a plain `final class` — no SwiftUI, no `@Observable`, no `ObservableObject`. It uses `withObservationTracking` directly, re-arming itself on every change for continuous observation.")
        }
    }

    private var logSection: some View {
        Section("Change Log") {
            if observer.log.isEmpty {
                Text("No events yet. Adjust the counter above.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(Array(observer.log.enumerated().reversed()), id: \.offset) { _, entry in
                    Text(entry)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("ObserverLogEntry")
                }
            }
        }
    }
}
