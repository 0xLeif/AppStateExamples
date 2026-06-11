import SwiftUI

// MARK: - Slices Section

/// Demonstrates `@Slice` and `@OptionalSlice` — editing a sub-field of a
/// composite state value without touching the rest of the struct.
internal struct SlicesSection: View {

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            List {
                Section("Slice / OptionalSlice") {
                    NavigationLink("Profile Slice Editor") {
                        ProfileSliceView()
                    }
                }
            }
            .navigationTitle("Slices")
        }
    }
}
