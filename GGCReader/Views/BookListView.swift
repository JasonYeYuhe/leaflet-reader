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
    @Query(sort: \Bookshelf.sortOrder) private var shelves: [Bookshelf]
    var storeManager = StoreManager.shared

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
        .searchable(text: $searchText, prompt: "Search books, authors, publishers")
        .navigationTitle("My Books")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        if canAddBook {
                            showingAddBook = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("Add Manually", systemImage: "pencil")
                    }
                    #if os(iOS)
                    Button {
                        if canAddBook {
                            showingISBNScanner = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("Scan ISBN Barcode", systemImage: "barcode.viewfinder")
                    }
                    Button {
                        if canAddBook {
                            showingScanner = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("Scan Book Cover", systemImage: "camera")
                    }
                    #endif
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Book")
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    // Sort options
                    Section("Sort By") {
                        ForEach(BookSortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(option.rawValue))
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    // Filter options
                    Section("Filter") {
                        ForEach(BookFilterOption.allCases, id: \.self) { option in
                            Button {
                                filterOption = option
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(option.rawValue))
                                    if filterOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        Button {
                            showingShelves = true
                        } label: {
                            Label("Manage Shelves", systemImage: "books.vertical")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            BookFormView()
        }
        #if os(iOS)
        .sheet(isPresented: $showingISBNScanner) {
            ISBNScannerView()
        }
        .sheet(isPresented: $showingScanner) {
            BookScannerView()
        }
        #endif
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
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
        .safeAreaInset(edge: .bottom) {
            if !storeManager.isPro && !books.isEmpty {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.blue)
                    Text("\(books.count)/\(StoreManager.freeBookLimit) books")
                        .font(.caption.bold())
                    Spacer()
                    if !canAddBook {
                        Button {
                            showingPaywall = true
                        } label: {
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
