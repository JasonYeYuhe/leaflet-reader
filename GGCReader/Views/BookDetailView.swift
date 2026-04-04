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

    // Decrease confirmation
    @State private var showingDecreaseConfirmation = false
    @State private var pendingNewPage: Int?

    // Undo
    @State private var undoSnapshot: UndoSnapshot?
    @State private var showingUndoBar = false
    @State private var undoDismissTask: Task<Void, Never>?

    // Celebration
    @State private var showCelebration = false

    private struct UndoSnapshot {
        let previousPage: Int
        let previousLastReadDate: Date?
        let deletedLogs: [(fromPage: Int, toPage: Int, date: Date, pagesRead: Int)]
        let mutatedLog: (id: UUID, originalToPage: Int, originalPagesRead: Int)?
        let createdLogID: UUID?
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                progressSection
                currentChapterSection
                quickUpdateSection
                if !book.isFinished && book.progressPercentage >= 0.9 {
                    markFinishedButton
                }
                actionButtonsSection
                chaptersPreviewSection
                notesPreviewSection
                readingLogSection
            }
            .padding()
        }
        .overlay {
            CelebrationView(
                isShowing: $showCelebration,
                emoji: "📚",
                message: "Book Finished!"
            )
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
        .confirmationDialog(
            "Confirm Page Decrease",
            isPresented: $showingDecreaseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Go Back", role: .destructive) {
                if let page = pendingNewPage {
                    commitPageUpdate(page)
                    pendingNewPage = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingNewPage = nil
                pageInput = String(book.currentPage)
            }
        } message: {
            if let pending = pendingNewPage {
                Text("This will go back \(book.currentPage - pending) pages and remove that reading history.")
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
                    HStack(spacing: 4) {
                        Label("Finished", systemImage: "checkmark.circle.fill")
                        if let date = book.lastReadDate {
                            Text("· \(date.formatted(.dateTime.month().day()))")
                        }
                    }
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
                if todayPages > 0 {
                    StatRow(label: "Today", value: "+\(todayPages) pages")
                }
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

    // MARK: - Helpers

    private var todayPages: Int {
        let calendar = Calendar.current
        return book.readingLogs
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.pagesRead }
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    // MARK: - Quick Update

    private var updateButtonDisabled: Bool {
        guard let newPage = Int(pageInput) else { return true }
        if newPage < 0 || newPage > book.totalPages { return true }
        if newPage == book.currentPage { return true }
        return false
    }

    private var validationMessage: String? {
        guard let newPage = Int(pageInput) else { return nil }
        if newPage > book.totalPages { return String(localized: "Exceeds total pages (\(book.totalPages))") }
        if newPage < 0 { return String(localized: "Page cannot be negative") }
        if newPage == book.currentPage { return String(localized: "Already at this page") }
        return nil
    }

    private var decreaseWarning: String? {
        guard let newPage = Int(pageInput),
              newPage < book.currentPage,
              book.currentPage > 0 else { return nil }
        let decrease = book.currentPage - newPage
        if decrease > 5 && Double(decrease) / Double(book.currentPage) > 0.05 {
            return String(localized: "Will remove \(decrease) pages of history")
        }
        return nil
    }

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
                .disabled(updateButtonDisabled)

                Spacer()

                HStack(spacing: 8) {
                    Button { stageDecrease(by: -1) } label: {
                        Image(systemName: "minus.circle")
                    }
                    .accessibilityLabel("Decrease 1 page")
                    Button { quickIncrement(by: 1) } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel("Add 1 page")
                    Button { quickIncrement(by: 5) } label: {
                        Text("+5")
                            .font(.caption.bold())
                    }
                    .accessibilityLabel("Add 5 pages")
                    Button { quickIncrement(by: 10) } label: {
                        Text("+10")
                            .font(.caption.bold())
                    }
                    .accessibilityLabel("Add 10 pages")
                }
                .buttonStyle(.bordered)
            }

            if let message = validationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let warning = decreaseWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if showingUndoBar {
                HStack {
                    Text("Updated to page \(book.currentPage)")
                        .font(.subheadline)
                    Spacer()
                    Button("Undo") {
                        performUndo()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(book.coverColor.color)
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.25), value: showingUndoBar)
    }

    // MARK: - Mark as Finished

    private var markFinishedButton: some View {
        Button {
            dismissKeyboard()
            commitPageUpdate(book.totalPages)
        } label: {
            Label("Mark as Finished", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
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
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteLog(log)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func deleteLog(_ log: ReadingLog) {
        // Dismiss any active undo bar since state has changed
        undoDismissTask?.cancel()
        withAnimation { showingUndoBar = false }
        undoSnapshot = nil

        modelContext.delete(log)

        // Recalculate currentPage from remaining logs
        let remainingMax = book.readingLogs
            .filter { $0.id != log.id }
            .max(by: { $0.toPage < $1.toPage })?.toPage ?? 0
        book.currentPage = remainingMax

        HapticManager.tap()
    }

    // MARK: - Actions

    private func updatePage() {
        dismissKeyboard()
        guard let newPage = Int(pageInput),
              newPage >= 0,
              newPage <= book.totalPages else { return }

        let oldPage = book.currentPage
        guard newPage != oldPage else { return }

        // Check if large decrease needs confirmation
        if newPage < oldPage {
            let decrease = oldPage - newPage
            if decrease > 5 && oldPage > 0 && Double(decrease) / Double(oldPage) > 0.05 {
                pendingNewPage = newPage
                showingDecreaseConfirmation = true
                return
            }
        }

        commitPageUpdate(newPage)
    }

    private func commitPageUpdate(_ newPage: Int) {
        let oldPage = book.currentPage
        guard newPage != oldPage else { return }
        let wasFinished = book.isFinished

        // Capture undo snapshot before mutating
        var deletedLogs: [(fromPage: Int, toPage: Int, date: Date, pagesRead: Int)] = []
        var mutatedLog: (id: UUID, originalToPage: Int, originalPagesRead: Int)?
        var createdLogID: UUID?

        if newPage > oldPage {
            let log = ReadingLog(fromPage: oldPage, toPage: newPage)
            log.book = book
            modelContext.insert(log)
            createdLogID = log.id
        } else {
            // Decrease: remove pages from most recent logs
            var pagesToRemove = oldPage - newPage
            let recentLogs = book.readingLogs.sorted { $0.date > $1.date }
            for log in recentLogs {
                guard pagesToRemove > 0 else { break }
                if log.pagesRead <= pagesToRemove {
                    // Save before deleting
                    deletedLogs.append((fromPage: log.fromPage, toPage: log.toPage, date: log.date, pagesRead: log.pagesRead))
                    pagesToRemove -= log.pagesRead
                    modelContext.delete(log)
                } else {
                    // Save before mutating
                    mutatedLog = (id: log.id, originalToPage: log.toPage, originalPagesRead: log.pagesRead)
                    log.toPage -= pagesToRemove
                    log.pagesRead = max(log.toPage - log.fromPage, 0)
                    pagesToRemove = 0
                }
            }
        }

        let snapshot = UndoSnapshot(
            previousPage: oldPage,
            previousLastReadDate: book.lastReadDate,
            deletedLogs: deletedLogs,
            mutatedLog: mutatedLog,
            createdLogID: createdLogID
        )

        book.currentPage = newPage
        book.lastReadDate = Date()

        if book.isFinished && !wasFinished {
            HapticManager.bookFinished()
            showCelebration = true
        } else {
            HapticManager.tap()
        }

        // Show undo bar
        undoSnapshot = snapshot
        undoDismissTask?.cancel()
        withAnimation { showingUndoBar = true }
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { showingUndoBar = false }
                undoSnapshot = nil
            }
        }
    }

    private func performUndo() {
        guard let snapshot = undoSnapshot else { return }

        // Restore page and date
        book.currentPage = snapshot.previousPage
        book.lastReadDate = snapshot.previousLastReadDate

        // Delete newly created log
        if let createdID = snapshot.createdLogID,
           let log = book.readingLogs.first(where: { $0.id == createdID }) {
            modelContext.delete(log)
        }

        // Restore mutated log
        if let mutated = snapshot.mutatedLog,
           let log = book.readingLogs.first(where: { $0.id == mutated.id }) {
            log.toPage = mutated.originalToPage
            log.pagesRead = mutated.originalPagesRead
        }

        // Re-create deleted logs
        for entry in snapshot.deletedLogs {
            let log = ReadingLog(fromPage: entry.fromPage, toPage: entry.toPage)
            log.date = entry.date
            log.pagesRead = entry.pagesRead
            log.book = book
            modelContext.insert(log)
        }

        // Clean up undo state
        undoDismissTask?.cancel()
        withAnimation { showingUndoBar = false }
        undoSnapshot = nil
        showCelebration = false
        HapticManager.tap()
    }

    private func quickIncrement(by delta: Int) {
        dismissKeyboard()
        let oldPage = book.currentPage
        let newPage = min(oldPage + delta, book.totalPages)
        guard newPage != oldPage else { return }
        commitPageUpdate(newPage)
    }

    private func stageDecrease(by delta: Int) {
        // Dismiss undo bar to avoid confusion
        if showingUndoBar {
            undoDismissTask?.cancel()
            withAnimation { showingUndoBar = false }
            undoSnapshot = nil
        }
        let current = Int(pageInput) ?? book.currentPage
        let newPage = max(current + delta, 0)
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
