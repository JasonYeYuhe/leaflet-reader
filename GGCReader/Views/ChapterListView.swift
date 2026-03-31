import SwiftUI
import SwiftData

struct ChapterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book
    @State private var showingAddChapter = false

    private var sortedChapters: [Chapter] {
        book.chapters.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                if sortedChapters.isEmpty {
                    ContentUnavailableView {
                        Label("No Chapters", systemImage: "list.number")
                    } description: {
                        Text("Add chapters to track your reading by section")
                    }
                } else {
                    ForEach(sortedChapters) { chapter in
                        ChapterRow(chapter: chapter, isCurrent: chapter.contains(page: book.currentPage), color: book.coverColor.color)
                    }
                    .onDelete(perform: deleteChapters)
                }
            }
            .navigationTitle("Chapters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddChapter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddChapter) {
                ChapterFormView(book: book, nextSortOrder: (sortedChapters.last?.sortOrder ?? -1) + 1)
            }
        }
    }

    private func deleteChapters(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedChapters[index])
        }
    }
}

struct ChapterRow: View {
    let chapter: Chapter
    let isCurrent: Bool
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: isCurrent ? "bookmark.fill" : "bookmark")
                .foregroundStyle(isCurrent ? color : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.name)
                    .font(.body)
                    .fontWeight(isCurrent ? .semibold : .regular)
                Text("Pages \(chapter.startPage) - \(chapter.endPage) (\(chapter.pageCount) pages)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isCurrent {
                Spacer()
                Text("Current")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color, in: Capsule())
            }
        }
    }
}
