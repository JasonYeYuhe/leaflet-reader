import SwiftUI
import SwiftData

enum BookSortOption: String, CaseIterable {
    case lastRead = "Last Read"
    case title = "Title"
    case dateAdded = "Date Added"
    case progress = "Progress"
}

enum BookFilterOption: String, CaseIterable {
    case all = "All"
    case reading = "Reading"
    case finished = "Finished"
}

struct BookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.lastReadDate, order: .reverse) private var books: [Book]
    @Binding var selectedBook: Book?
    @State private var showingAddBook = false
    @State private var showingScanner = false
    @State private var showingISBNScanner = false
    @State private var showingPaywall = false
    @State private var showingShelves = false
    @State private var searchText = ""
    @State private var sortOption: BookSortOption = .lastRead
    @State private var filterOption: BookFilterOption = .all
    @AppStorage("bookViewMode") private var viewMode: BookViewMode = .list
    @State private var selectedTagFilter: Tag?
    @State private var isSelectMode = false
    @State private var selectedBookIDs: Set<UUID> = []
    @State private var showingBatchShelfPicker = false
    @State private var showingBatchDeleteConfirm = false
    @Query(sort: \Bookshelf.sortOrder) private var shelves: [Bookshelf]
    @Query(sort: \Tag.name) private var allTags: [Tag]
    var storeManager = StoreManager.shared

    enum BookViewMode: String {
        case list, grid
    }

    private var canAddBook: Bool {
        storeManager.isPro || books.count < StoreManager.freeBookLimit
    }

    private var filteredBooks: [Book] {
        var result = books

        // Search: title, author, publisher
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText) ||
                $0.publisher.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter
        switch filterOption {
        case .all: break
        case .reading: result = result.filter { !$0.isFinished }
        case .finished: result = result.filter { $0.isFinished }
        }

        // Tag filter
        if let tag = selectedTagFilter {
            result = result.filter { $0.tags.contains { $0.id == tag.id } }
        }

        // Sort
        switch sortOption {
        case .lastRead:
            result.sort { ($0.lastReadDate ?? .distantPast) > ($1.lastReadDate ?? .distantPast) }
        case .title:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .progress:
            result.sort { $0.progressPercentage > $1.progressPercentage }
        }

        return result
    }

    private var readingBooks: [Book] {
        filteredBooks.filter { !$0.isFinished }
    }

    private var finishedBooks: [Book] {
        filteredBooks.filter { $0.isFinished }
    }

    var body: some View {
        Group {
            if viewMode == .grid {
                gridView
            } else {
                listView
            }
        }
        .searchable(text: $searchText, prompt: "Search books, authors, publishers")
        .navigationTitle("My Books")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingAddBook) { BookFormView() }
        #if os(iOS)
        .sheet(isPresented: $showingISBNScanner) { ISBNScannerView() }
        .sheet(isPresented: $showingScanner) { BookScannerView() }
        #endif
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingShelves) {
            NavigationStack {
                BookshelfListView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingShelves = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingBatchShelfPicker) {
            BatchShelfPickerView(bookIDs: selectedBookIDs, onDone: {
                isSelectMode = false
                selectedBookIDs.removeAll()
            })
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    // MARK: - Grid View

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    private var gridMinWidth: CGFloat {
        #if os(iOS)
        return sizeClass == .regular ? 120 : 100
        #else
        return 120
        #endif
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: gridMinWidth), spacing: 16)], spacing: 16) {
                ForEach(filteredBooks) { book in
                    Button {
                        if isSelectMode {
                            toggleSelection(book)
                        } else {
                            selectedBook = book
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                BookCoverView(title: book.title, color: book.coverColor, size: 90, imageData: book.coverImageData)
                                if isSelectMode {
                                    Image(systemName: selectedBookIDs.contains(book.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedBookIDs.contains(book.id) ? .blue : .secondary)
                                        .background(.white, in: Circle())
                                        .offset(x: 4, y: -4)
                                }
                            }
                            Text(book.title)
                                .font(.caption)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text("\(Int(book.progressPercentage * 100))%")
                                .font(.caption2)
                                .foregroundStyle(book.coverColor.color)
                        }
                        .frame(width: 100)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - List View

    private var listView: some View {
        List(selection: $selectedBook) {
            if !shelves.isEmpty && searchText.isEmpty {
                Section("Shelves") {
                    ForEach(shelves) { shelf in
                        NavigationLink {
                            BookshelfDetailView(shelf: shelf)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: shelf.icon)
                                    .foregroundStyle(colorFor(shelf.colorName))
                                    .frame(width: 24)
                                Text(shelf.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(shelf.books.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if readingBooks.isEmpty && finishedBooks.isEmpty {
                ContentUnavailableView {
                    Label("No Books", systemImage: "book.closed")
                } description: {
                    Text("Tap + to add your first book")
                }
            }

            if filterOption == .all {
                // Grouped view
                if !readingBooks.isEmpty {
                    Section("Reading") {
                        ForEach(readingBooks) { book in
                            NavigationLink(value: book) {
                                BookRowView(book: book)
                            }
                        }
                        .onDelete { indexSet in
                            deleteBooks(from: readingBooks, at: indexSet)
                        }
                    }
                }

                if !finishedBooks.isEmpty {
                    Section("Finished") {
                        ForEach(finishedBooks) { book in
                            NavigationLink(value: book) {
                                BookRowView(book: book)
                            }
                        }
                        .onDelete { indexSet in
                            deleteBooks(from: finishedBooks, at: indexSet)
                        }
                    }
                }
            } else {
                // Flat view when filtered
                ForEach(filteredBooks) { book in
                    NavigationLink(value: book) {
                        BookRowView(book: book)
                    }
                }
                .onDelete { indexSet in
                    deleteBooks(from: filteredBooks, at: indexSet)
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if isSelectMode {
                Button("Done") {
                    isSelectMode = false
                    selectedBookIDs.removeAll()
                }
            } else {
                Menu {
                    Button {
                        if canAddBook { showingAddBook = true } else { showingPaywall = true }
                    } label: {
                        Label("Add Manually", systemImage: "pencil")
                    }
                    #if os(iOS)
                    Button {
                        if canAddBook { showingISBNScanner = true } else { showingPaywall = true }
                    } label: {
                        Label("Scan ISBN Barcode", systemImage: "barcode.viewfinder")
                    }
                    Button {
                        if canAddBook { showingScanner = true } else { showingPaywall = true }
                    } label: {
                        Label("Scan Book Cover", systemImage: "camera")
                    }
                    #endif
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Book")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Menu {
                Section("Sort By") {
                    ForEach(BookSortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(LocalizedStringKey(option.rawValue))
                                if sortOption == option { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
                Section("Filter") {
                    ForEach(BookFilterOption.allCases, id: \.self) { option in
                        Button {
                            filterOption = option
                        } label: {
                            HStack {
                                Text(LocalizedStringKey(option.rawValue))
                                if filterOption == option { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
                if !allTags.isEmpty {
                    Section("Tags") {
                        Button {
                            selectedTagFilter = nil
                        } label: {
                            HStack {
                                Text("All Tags")
                                if selectedTagFilter == nil { Image(systemName: "checkmark") }
                            }
                        }
                        ForEach(allTags) { tag in
                            Button {
                                selectedTagFilter = tag
                            } label: {
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(tag.color.color)
                                    Text(tag.name)
                                    if selectedTagFilter?.id == tag.id { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                }
                Section("View") {
                    Button {
                        viewMode = viewMode == .list ? .grid : .list
                        isSelectMode = false
                        selectedBookIDs.removeAll()
                    } label: {
                        Label(viewMode == .list ? "Grid View" : "List View",
                              systemImage: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                    }
                    Button {
                        isSelectMode.toggle()
                        if !isSelectMode { selectedBookIDs.removeAll() }
                    } label: {
                        Label(isSelectMode ? "Cancel Select" : "Select Books", systemImage: "checkmark.circle")
                    }
                }
                Section {
                    Button { showingShelves = true } label: {
                        Label("Manage Shelves", systemImage: "books.vertical")
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        if isSelectMode && !selectedBookIDs.isEmpty {
            HStack(spacing: 16) {
                Text("\(selectedBookIDs.count) selected")
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    showingBatchShelfPicker = true
                } label: {
                    Label("Add to Shelf", systemImage: "books.vertical")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                Button(role: .destructive) {
                    showingBatchDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .confirmationDialog("Delete \(selectedBookIDs.count) books?", isPresented: $showingBatchDeleteConfirm, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) { deleteBatchSelected() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action cannot be undone.")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        } else if !storeManager.isPro && !books.isEmpty {
            HStack {
                Image(systemName: "book.closed")
                    .foregroundStyle(.blue)
                Text("\(books.count)/\(StoreManager.freeBookLimit) books")
                    .font(.caption.bold())
                Spacer()
                if !canAddBook {
                    Button { showingPaywall = true } label: {
                        Label("Upgrade", systemImage: "crown.fill")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Batch Actions

    private func toggleSelection(_ book: Book) {
        if selectedBookIDs.contains(book.id) {
            selectedBookIDs.remove(book.id)
        } else {
            selectedBookIDs.insert(book.id)
        }
    }

    private func deleteBatchSelected() {
        // Only delete books that are currently visible in the filtered list
        for book in filteredBooks where selectedBookIDs.contains(book.id) {
            modelContext.delete(book)
        }
        selectedBookIDs.removeAll()
        isSelectMode = false
        HapticManager.tap()
    }

    private func deleteBooks(from list: [Book], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(list[index])
        }
    }
}

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            BookCoverView(title: book.title, color: book.coverColor, size: 44, imageData: book.coverImageData)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(Int(book.progressPercentage * 100))%")
                .font(.caption.weight(.semibold))
                .foregroundStyle(book.coverColor.color)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}
