#if canImport(SwiftData)
import SwiftUI
import SwiftData
import AppState

// MARK: - Todo List View

/// A to-do list powered by AppState's `@ModelState` / `ModelContainer` dependency.
///
/// - `@Query` drives the live, reactive list so SwiftUI updates on every store change.
/// - `$todos` (the `ModelState` projected value) provides lenient and strict mutations.
/// - A do/catch around `$todos.strict.insert(_:)` surfaces errors in the UI.
internal struct TodoListView: View {

    // MARK: Query (reactive list)

    @Query(sort: \TodoItem.createdAt) private var items: [TodoItem]

    // MARK: ModelState (mutations)

    @ModelState(\.todos) private var todos: [TodoItem]

    // MARK: State

    @State private var newTitle: String = ""
    @State private var insertError: String? = nil
    @State private var showInsertError: Bool = false
    @FocusState private var isNewTitleFocused: Bool

    // MARK: Body

    internal var body: some View {
        List {
            addSection
            itemsSection
            strictInsertSection
        }
        .navigationTitle("Todo List (@ModelState)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Delete All", role: .destructive) {
                    $todos.deleteAll()
                }
                .disabled(items.isEmpty)
                .accessibilityIdentifier("DeleteAllButton")
            }
        }
        .alert("Insert Error", isPresented: $showInsertError, presenting: insertError) { _ in
            Button("OK") { insertError = nil }
        } message: { errorMessage in
            Text(errorMessage)
        }
    }

    // MARK: Private Views

    private var addSection: some View {
        Section {
            HStack {
                TextField("New item title", text: $newTitle)
                    .focused($isNewTitleFocused)
                    .accessibilityIdentifier("NewItemField")
                Button("Add") {
                    addItem()
                }
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("AddItemButton")
            }
        } header: {
            Text("Add Item (lenient)")
        } footer: {
            Text("Uses `$todos.insert(_:)` — lenient, logs and swallows errors.")
        }
    }

    private var itemsSection: some View {
        Section("Items (\(items.count))") {
            if items.isEmpty {
                Text("No items yet. Add one above.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    TodoRowView(item: item)
                }
                .onDelete { indexSet in
                    deleteItems(at: indexSet)
                }
            }
        }
    }

    private var strictInsertSection: some View {
        Section {
            Button("Insert via strict.insert(_:)") {
                insertStrict()
            }
            .accessibilityIdentifier("StrictInsertButton")
        } header: {
            Text("Strict Insert (throwing)")
        } footer: {
            Text("`$todos.strict.insert(_:)` throws on failure — errors are caught and surfaced in the UI.")
        }
    }

    // MARK: Private Methods

    private func addItem() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        $todos.insert(TodoItem(title: title))
        newTitle = ""
        isNewTitleFocused = false
    }

    private func deleteItems(at indexSet: IndexSet) {
        for index in indexSet {
            $todos.delete(items[index])
        }
    }

    private func insertStrict() {
        let item = TodoItem(title: "Strict item — \(Date().formatted(date: .omitted, time: .shortened))")
        do {
            try $todos.strict.insert(item)
        } catch {
            insertError = error.localizedDescription
            showInsertError = true
        }
    }
}

// MARK: - Todo Row View

/// A single row in the to-do list, with an inline completion toggle.
private struct TodoRowView: View {

    // MARK: Properties

    @Bindable private var item: TodoItem

    // MARK: Initializer

    fileprivate init(item: TodoItem) {
        self.item = item
    }

    // MARK: Body

    fileprivate var body: some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isCompleted ? .green : .secondary)
                .onTapGesture {
                    item.isCompleted.toggle()
                }
                .accessibilityLabel(item.isCompleted ? "Mark incomplete" : "Mark complete")
                .accessibilityIdentifier("TodoCompletionToggle")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .accessibilityIdentifier("TodoItemTitle")

                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
#endif
