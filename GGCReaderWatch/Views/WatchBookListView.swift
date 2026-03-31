import SwiftUI
import SwiftData

struct WatchBookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.lastReadDate, order: .reverse) private var books: [Book]

    var body: some View {
        NavigationStack {
            if books.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Books")
                        .font(.headline)
                    Text("Add books on iPhone or iPad")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                List(books) { book in
                    NavigationLink {
                        WatchBookDetailView(book: book)
                    } label: {
                        WatchBookRow(book: book)
                    }
                }
            }
        }
        .navigationTitle("Books")
    }
}

struct WatchBookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(book.coverColor.color.gradient)
                .frame(width: 24, height: 24)
                .overlay {
                    Text(String(book.title.prefix(1)))
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.caption)
                    .lineLimit(1)
                Text("\(Int(book.progressPercentage * 100))% - p.\(book.currentPage)/\(book.totalPages)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
