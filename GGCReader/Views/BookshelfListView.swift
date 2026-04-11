import SwiftUI
import SwiftData

struct BookshelfListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bookshelf.sortOrder) private var shelves: [Bookshelf]
    @State private var showingAddShelf = false
    @State private var editingShelf: Bookshelf?

    var body: some View {
        List {
            if shelves.isEmpty {
                ContentUnavailableView {
                    Label("No Bookshelves", systemImage: "books.vertical")
                } description: {
                    Text("Create shelves to organize your books")
                }
            }

            ForEach(shelves) { shelf in
                NavigationLink(value: shelf) {
                    HStack(spacing: 12) {
                        Image(systemName: shelf.icon)
                            .foregroundStyle(colorFor(shelf.colorName))
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shelf.name)
                                .font(.headline)
                            Text("\(shelf.books.count) books")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(shelf)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        editingShelf = shelf
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .navigationTitle("Bookshelves")
        .navigationDestination(for: Bookshelf.self) { shelf in
            BookshelfDetailView(shelf: shelf)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddShelf = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddShelf) {
            BookshelfFormView()
        }
        .sheet(item: $editingShelf) { shelf in
            BookshelfFormView(shelfToEdit: shelf)
        }
    }
}

// MARK: - Bookshelf Detail

struct BookshelfDetailView: View {
    @Bindable var shelf: Bookshelf
    @State private var showingAddBooks = false

    var body: some View {
        List {
            if shelf.books.isEmpty {
                ContentUnavailableView {
                    Label("Empty Shelf", systemImage: shelf.icon)
                } description: {
                    Text("Tap + to add books to this shelf")
                }
            }

            ForEach(shelf.books.sorted { $0.title < $1.title }) { book in
                HStack(spacing: 12) {
                    BookCoverView(title: book.title, color: book.coverColor, size: 40, imageData: book.coverImageData)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text(book.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("\(Int(book.progressPercentage * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(book.coverColor.color)
                        .monospacedDigit()
                }
                .swipeActions {
                    Button {
                        shelf.books.removeAll { $0.id == book.id }
                    } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                    .tint(.orange)
                }
            }
        }
        .navigationTitle(shelf.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddBooks = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBooks) {
            AddBooksToShelfView(shelf: shelf)
        }
    }
}

// MARK: - Bookshelf Form

struct BookshelfFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var shelfToEdit: Bookshelf?

    @State private var name = ""
    @State private var selectedIcon = "books.vertical"
    @State private var selectedColor = "blue"

    private var isEditing: Bool { shelfToEdit != nil }

    private static let icons = [
        "books.vertical", "book", "book.closed", "bookmark",
        "heart", "star", "flag", "folder",
        "lightbulb", "graduationcap", "globe", "theatermasks",
        "leaf", "brain", "puzzlepiece", "trophy"
    ]

    private static let colors = [
        "blue", "red", "green", "orange", "purple",
        "pink", "teal", "indigo", "brown", "mint"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Shelf name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(Self.icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(
                                    selectedIcon == icon ? colorFor(selectedColor).opacity(0.2) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .foregroundStyle(selectedIcon == icon ? colorFor(selectedColor) : .secondary)
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 10) {
                        ForEach(Self.colors, id: \.self) { color in
                            Circle()
                                .fill(colorFor(color).gradient)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Shelf" : "New Shelf")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveShelf()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let shelf = shelfToEdit {
                    name = shelf.name
                    selectedIcon = shelf.icon
                    selectedColor = shelf.colorName
                }
            }
        }
    }

    private func saveShelf() {
        if let shelf = shelfToEdit {
            shelf.name = name.trimmingCharacters(in: .whitespaces)
            shelf.icon = selectedIcon
            shelf.colorName = selectedColor
        } else {
            let shelf = Bookshelf(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: selectedIcon,
                colorName: selectedColor
            )
            modelContext.insert(shelf)
        }
        dismiss()
    }
}

// MARK: - Add Books to Shelf

struct AddBooksToShelfView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Book.title) private var allBooks: [Book]
    @Bindable var shelf: Bookshelf
    @State private var searchText = ""

    private var availableBooks: [Book] {
        let shelfBookIDs = Set(shelf.books.map(\.id))
        var filtered = allBooks.filter { !shelfBookIDs.contains($0.id) }
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        return filtered
    }

    var body: some View {
        NavigationStack {
            List {
                if availableBooks.isEmpty {
                    ContentUnavailableView {
                        Label("No Books Available", systemImage: "book.closed")
                    } description: {
                        Text(allBooks.isEmpty ? "Add books first" : "All books are already on this shelf")
                    }
                }

                ForEach(availableBooks) { book in
                    Button {
                        shelf.books.append(book)
                    } label: {
                        HStack(spacing: 12) {
                            BookCoverView(title: book.title, color: book.coverColor, size: 36, imageData: book.coverImageData)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(book.author)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search books")
            .navigationTitle("Add Books")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

