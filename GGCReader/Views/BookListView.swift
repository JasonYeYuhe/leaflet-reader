import SwiftUI
import SwiftData

struct BookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.lastReadDate, order: .reverse) private var books: [Book]
    @Binding var selectedBook: Book?
    @State private var showingAddBook = false
    @State private var showingScanner = false
    @State private var showingPaywall = false
    @State private var searchText = ""
    var storeManager = StoreManager.shared

    private var canAddBook: Bool {
        storeManager.isPro || books.count < StoreManager.freeBookLimit
    }

    private var filteredBooks: [Book] {
        if searchText.isEmpty { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var readingBooks: [Book] {
        filteredBooks.filter { !$0.isFinished }
    }

    private var finishedBooks: [Book] {
        filteredBooks.filter { $0.isFinished }
    }

    var body: some View {
        List(selection: $selectedBook) {
            if readingBooks.isEmpty && finishedBooks.isEmpty {
                ContentUnavailableView {
                    Label("No Books", systemImage: "book.closed")
                } description: {
                    Text("Tap + to add your first book")
                }
            }

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
        }
        .searchable(text: $searchText, prompt: "Search books")
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
            }
        }
        .sheet(isPresented: $showingAddBook) {
            BookFormView()
        }
        #if os(iOS)
        .sheet(isPresented: $showingScanner) {
            BookScannerView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        #endif
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
