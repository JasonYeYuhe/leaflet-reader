import SwiftUI
import SwiftData
import WidgetKit

struct QuickPageUpdateSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    @Binding var pageInput: String
    @Binding var showCelebration: Bool

    // Decrease confirmation
    @State private var showingDecreaseConfirmation = false
    @State private var pendingNewPage: Int?

    // Undo
    @State private var undoSnapshot: UndoSnapshot?
    @State private var showingUndoBar = false
    @State private var undoDismissTask: Task<Void, Never>?

    private struct UndoSnapshot {
        let previousPage: Int
        let previousLastReadDate: Date?
        let deletedLogs: [(fromPage: Int, toPage: Int, date: Date, pagesRead: Int)]
        let mutatedLog: (id: UUID, originalToPage: Int, originalPagesRead: Int)?
        let createdLogID: UUID?
    }

    // MARK: - Computed

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

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update Progress")
                .font(.headline)

            HStack(spacing: 12) {
                TextField(book.bookType == .audiobook ? "Minutes" : "Page", text: $pageInput)
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
                    .help("Decrease 1 page")
                    Button { quickIncrement(by: 1) } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel("Add 1 page")
                    .help("Add 1 page")
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
                    Text(book.bookType == .audiobook ? "Updated to \(book.currentPage) min" : "Updated to page \(book.currentPage)")
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
    }

    // MARK: - Mark Finished

    func markAsFinished() {
        dismissKeyboard()
        commitPageUpdate(book.totalPages)
    }

    // MARK: - Actions

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private func updatePage() {
        dismissKeyboard()
        guard let newPage = Int(pageInput),
              newPage >= 0,
              newPage <= book.totalPages else { return }

        let oldPage = book.currentPage
        guard newPage != oldPage else { return }

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

        var deletedLogs: [(fromPage: Int, toPage: Int, date: Date, pagesRead: Int)] = []
        var mutatedLog: (id: UUID, originalToPage: Int, originalPagesRead: Int)?
        var createdLogID: UUID?

        if newPage > oldPage {
            let log = ReadingLog(fromPage: oldPage, toPage: newPage)
            log.book = book
            modelContext.insert(log)
            createdLogID = log.id
        } else {
            var pagesToRemove = oldPage - newPage
            let recentLogs = book.readingLogs.sorted { $0.date > $1.date }
            for log in recentLogs {
                guard pagesToRemove > 0 else { break }
                if log.pagesRead <= pagesToRemove {
                    deletedLogs.append((fromPage: log.fromPage, toPage: log.toPage, date: log.date, pagesRead: log.pagesRead))
                    pagesToRemove -= log.pagesRead
                    modelContext.delete(log)
                } else {
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
            book.dateFinished = Date()
            HapticManager.bookFinished()
            showCelebration = true
        } else {
            HapticManager.tap()
        }

        undoSnapshot = snapshot
        undoDismissTask?.cancel()
        withAnimation { showingUndoBar = true }
        WidgetCenter.shared.reloadAllTimelines()
        let justFinished = book.isFinished && !wasFinished
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { showingUndoBar = false }
                undoSnapshot = nil
                if justFinished {
                    ReviewManager.recordBookFinished()
                }
            }
        }
    }

    private func performUndo() {
        guard let snapshot = undoSnapshot else { return }

        book.currentPage = snapshot.previousPage
        book.lastReadDate = snapshot.previousLastReadDate
        if !book.isFinished {
            book.dateFinished = nil
        }

        if let createdID = snapshot.createdLogID,
           let log = book.readingLogs.first(where: { $0.id == createdID }) {
            modelContext.delete(log)
        }

        if let mutated = snapshot.mutatedLog,
           let log = book.readingLogs.first(where: { $0.id == mutated.id }) {
            log.toPage = mutated.originalToPage
            log.pagesRead = mutated.originalPagesRead
        }

        for entry in snapshot.deletedLogs {
            let log = ReadingLog(fromPage: entry.fromPage, toPage: entry.toPage)
            log.date = entry.date
            log.pagesRead = entry.pagesRead
            log.book = book
            modelContext.insert(log)
        }

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
