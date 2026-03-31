import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    @State private var showingEditBook = false
    @State private var showingChapters = false
    @State private var showingNotes = false
    @State private var showingTimer = false
    @State private var pageInput = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                progressSection
                currentChapterSection
                quickUpdateSection
                actionButtonsSection
                chaptersPreviewSection
                notesPreviewSection
                readingLogSection
            }
            .padding()
        }
        .navigationTitle(book.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditBook = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditBook) {
            BookFormView(bookToEdit: book)
        }
        .sheet(isPresented: $showingChapters) {
            ChapterListView(book: book)
        }
        .sheet(isPresented: $showingNotes) {
            BookNotesView(book: book)
        }
        .sheet(isPresented: $showingTimer) {
            NavigationStack {
                ReadingTimerView(book: book)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingTimer = false }
                        }
                    }
            }
        }
        .onAppear {
            pageInput = String(book.currentPage)
        }
        .onChange(of: book.currentPage) { _, newValue in
            pageInput = String(newValue)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 20) {
            BookCoverView(title: book.title, color: book.coverColor, size: 90, imageData: book.coverImageData)

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Added \(book.dateAdded.formatted(.dateTime.month().day().year()))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if book.isFinished {
                    Label("Finished", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
            Spacer()
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        HStack(spacing: 30) {
            ProgressRingView(
                progress: book.progressPercentage,
                color: book.coverColor.color,
                size: 100
            )

            VStack(alignment: .leading, spacing: 12) {
                StatRow(label: "Current Page", value: "\(book.currentPage)")
                StatRow(label: "Total Pages", value: "\(book.totalPages)")
                StatRow(label: "Remaining", value: "\(book.pagesRemaining)")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Current Chapter

    @ViewBuilder
    private var currentChapterSection: some View {
        if let chapter = book.currentChapter {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(book.coverColor.color)
                VStack(alignment: .leading) {
                    Text("Currently Reading")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(chapter.name)
                        .font(.headline)
                }
                Spacer()
                Text("p.\(chapter.startPage)-\(chapter.endPage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Quick Update

    private var quickUpdateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update Progress")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("Page", text: $pageInput)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .frame(width: 80)

                Button("Update") {
                    updatePage()
                }
                .buttonStyle(.borderedProminent)
                .tint(book.coverColor.color)
                .disabled(Int(pageInput) == nil)

                Spacer()

                HStack(spacing: 8) {
                    Button { adjustPage(by: -1) } label: {
                        Image(systemName: "minus.circle")
                    }
                    Button { adjustPage(by: 1) } label: {
                        Image(systemName: "plus.circle")
                    }
                    Button { adjustPage(by: 5) } label: {
                        Text("+5")
                            .font(.caption.bold())
                    }
                    Button { adjustPage(by: 10) } label: {
                        Text("+10")
                            .font(.caption.bold())
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button {
                showingTimer = true
            } label: {
                Label("Timer", systemImage: "timer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(book.coverColor.color)

            Button {
                showingNotes = true
            } label: {
                Label("Notes (\(book.notes.count))", systemImage: "note.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(book.coverColor.color)
        }

    }

    // MARK: - Notes Preview

    private var notesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Button {
                    showingNotes = true
                } label: {
                    Text("View All (\(book.notes.count))")
                        .font(.subheadline)
                }
            }

            if book.notes.isEmpty {
                Text("No notes yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                let recent = book.notes.sorted { $0.dateCreated > $1.dateCreated }.prefix(3)
                ForEach(Array(recent)) { note in
                    HStack {
                        if note.page > 0 {
                            Text("p.\(note.page)")
                                .font(.caption2.bold())
                                .foregroundStyle(book.coverColor.color)
                        }
                        Text(note.content)
                            .font(.caption)
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Chapters Preview

    private var chaptersPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chapters")
                    .font(.headline)
                Spacer()
                Button {
                    showingChapters = true
                } label: {
                    Text("Manage")
                        .font(.subheadline)
                }
            }

            if book.chapters.isEmpty {
                Text("No chapters added yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                let sorted = book.chapters.sorted { $0.sortOrder < $1.sortOrder }
                ForEach(sorted.prefix(5)) { chapter in
                    HStack {
                        Image(systemName: chapter.contains(page: book.currentPage) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(chapter.contains(page: book.currentPage) ? book.coverColor.color : .secondary)
                            .font(.caption)
                        Text(chapter.name)
                            .font(.subheadline)
                            .fontWeight(chapter.contains(page: book.currentPage) ? .semibold : .regular)
                        Spacer()
                        Text("p.\(chapter.startPage)-\(chapter.endPage)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                if sorted.count > 5 {
                    Text("and \(sorted.count - 5) more...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Reading Log

    private var readingLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Log")
                .font(.headline)

            if book.readingLogs.isEmpty {
                Text("No reading sessions recorded yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                let sorted = book.readingLogs.sorted { $0.date > $1.date }
                ForEach(sorted.prefix(10)) { log in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(log.date.formatted(.dateTime.month().day().hour().minute()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("p.\(log.fromPage) -> p.\(log.toPage)")
                            .font(.caption)
                        Text("+\(log.pagesRead) pages")
                            .font(.caption.bold())
                            .foregroundStyle(book.coverColor.color)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func updatePage() {
        guard let newPage = Int(pageInput),
              newPage >= 0,
              newPage <= book.totalPages else { return }

        let oldPage = book.currentPage
        guard newPage != oldPage else { return }

        if newPage > oldPage {
            let log = ReadingLog(fromPage: oldPage, toPage: newPage)
            log.book = book
            modelContext.insert(log)
        } else {
            // Decrease: remove pages from most recent logs
            var pagesToRemove = oldPage - newPage
            let recentLogs = book.readingLogs.sorted { $0.date > $1.date }
            for log in recentLogs {
                guard pagesToRemove > 0 else { break }
                if log.pagesRead <= pagesToRemove {
                    pagesToRemove -= log.pagesRead
                    modelContext.delete(log)
                } else {
                    log.toPage -= pagesToRemove
                    log.pagesRead = max(log.toPage - log.fromPage, 0)
                    pagesToRemove = 0
                }
            }
        }

        book.currentPage = newPage
        book.lastReadDate = Date()

        if book.isFinished {
            HapticManager.bookFinished()
        } else {
            HapticManager.tap()
        }
    }

    private func adjustPage(by delta: Int) {
        let current = Int(pageInput) ?? book.currentPage
        let newPage = min(max(current + delta, 0), book.totalPages)
        pageInput = String(newPage)
    }
}

struct StatRow: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .monospacedDigit()
        }
    }
}
