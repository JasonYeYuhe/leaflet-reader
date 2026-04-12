import SwiftUI
import SwiftData

struct BatchShelfPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Bookshelf.sortOrder) private var shelves: [Bookshelf]

    let bookIDs: Set<UUID>
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if shelves.isEmpty {
                    ContentUnavailableView {
                        Label("No Shelves", systemImage: "books.vertical")
                    } description: {
                        Text("Create a shelf first in Manage Shelves")
                    }
                } else {
                    ForEach(shelves) { shelf in
                        Button {
                            addBooksToShelf(shelf)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: shelf.icon)
                                    .foregroundStyle(colorFor(shelf.colorName))
                                    .frame(width: 24)
                                Text(shelf.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(shelf.books.count) books")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Shelf")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addBooksToShelf(_ shelf: Bookshelf) {
        // Fetch only the selected books by ID
        for id in bookIDs {
            let descriptor = FetchDescriptor<Book>(predicate: #Predicate<Book> { $0.id == id })
            if let book = try? modelContext.fetch(descriptor).first {
                if !shelf.books.contains(where: { $0.id == book.id }) {
                    shelf.books.append(book)
                }
            }
        }
        HapticManager.notification(.success)
        dismiss()
        onDone()
    }
}
