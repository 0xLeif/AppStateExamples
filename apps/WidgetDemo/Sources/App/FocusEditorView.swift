import SwiftUI
import AppState
import WidgetKit
import WidgetDemoCore

// MARK: - Focus Editor View

/// The main app screen. Lets the user edit `focusTitle` and increment `focusCount`.
/// Every mutation calls `WidgetCenter.shared.reloadAllTimelines()` so the widget
/// refreshes immediately.
internal struct FocusEditorView: View {

    // MARK: State

    @StoredState(\.focusTitle) private var focusTitle: String
    @StoredState(\.focusCount) private var focusCount: Int

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            Form {
                titleSection
                countSection
                actionsSection
            }
            .navigationTitle("Focus Session")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            TextField("Session Title", text: $focusTitle)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .onChange(of: focusTitle) { _, _ in
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .accessibilityIdentifier("FocusTitleField")
        } header: {
            Text("Session Title")
        } footer: {
            Text("Displayed on the widget. Stored in the shared App Group UserDefaults.")
        }
    }

    private var countSection: some View {
        Section {
            LabeledContent("Completed Increments") {
                Text("\(focusCount)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("FocusCountValue")
            }
        } header: {
            Text("Focus Count")
        } footer: {
            Text("Tap \"Increment\" to add one. The widget reflects the updated count immediately.")
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                focusCount += 1
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Label("Increment Count", systemImage: "plus.circle.fill")
            }
            .accessibilityIdentifier("IncrementButton")

            Button(role: .destructive) {
                focusTitle = "Focus Session"
                focusCount = 0
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Label("Reset Session", systemImage: "arrow.counterclockwise")
            }
            .accessibilityIdentifier("ResetButton")
        }
    }
}
