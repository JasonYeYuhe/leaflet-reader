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
    @State private var showCelebration = false
    @State private var showingRatingPrompt = false
    @State private var showingShareCard = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                if book.isFinished {
                    ratingSection
                }
                progressSection
                currentChapterSection
                QuickPageUpdateSection(
                    book: book,
                    pageInput: $pageInput,
                    showCelebration: $showCelebration
                )
                if !book.isFinished && book.progressPercentage >= 0.9 {
                    markFinishedButton
                }
                shelfBadgesSection
                tagSection
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
        .onChange(of: showCelebration) { old, new in
            if old && !new && book.isFinished && book.rating == nil {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    showingRatingPrompt = true
                }
            }
        }
        .navigationTitle(book.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    if book.isFinished {
                        Button {
                            showingShareCard = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .help("Share Reading Card")
                    }
                    Button {
                        showingEditBook = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .help("Edit Book")
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
        .sheet(isPresented: $showingRatingPrompt) {
            RatingPromptView(book: book)
        }
        .sheet(isPresented: $showingShareCard) {
            ShareCardSheet(book: book)
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
                HStack(spacing: 6) {
                    if book.bookType != .physical {
                        Label(book.bookType.displayName, systemImage: book.bookType.icon)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    if !book.genre.isEmpty {
                        Text(book.genre)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
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
                StatRow(label: LocalizedStringKey(book.bookType.currentLabel), value: book.bookType == .audiobook ? formatMinutes(book.currentPage) : "\(book.currentPage)")
                StatRow(label: LocalizedStringKey(book.bookType.totalLabel), value: book.bookType == .audiobook ? formatMinutes(book.totalPages) : "\(book.totalPages)")
                StatRow(label: "Remaining", value: book.bookType == .audiobook ? formatMinutes(book.pagesRemaining) : "\(book.pagesRemaining)")
                if todayPages > 0 {
                    StatRow(label: "Today", value: "+\(todayPages) \(book.bookType.unitName)")
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

    // MARK: - Shelf Badges

    @State private var showingShelfPicker = false

    @ViewBuilder
    private var shelfBadgesSection: some View {
        if true {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Shelves")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showingShelfPicker = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                    }
                }

                if book.shelves.isEmpty {
                    Text("Not on any shelf")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(book.shelves.sorted { $0.name < $1.name }) { shelf in
                            HStack(spacing: 4) {
                                Image(systemName: shelf.icon)
                                    .font(.caption2)
                                Text(shelf.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorFor(shelf.colorName).opacity(0.12), in: Capsule())
                            .foregroundStyle(colorFor(shelf.colorName))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShelfPicker) {
                BookShelfPickerView(book: book)
            }
        }
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Rating")
                    .font(.headline)
                Spacer()
                if book.rating != nil {
                    Button {
                        showingShareCard = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= (book.rating ?? 0) ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(star <= (book.rating ?? 0) ? .yellow : .secondary.opacity(0.4))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                book.rating = (book.rating == star) ? nil : star
                            }
                            HapticManager.selection()
                        }
                }
                Spacer()
            }

            if let review = book.review, !review.isEmpty {
                Text(review)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }

            Button {
                showingRatingPrompt = true
            } label: {
                Text(book.review?.isEmpty == false ? "Edit Review" : "Write a Review")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Tags

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            TagPickerView(book: book)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private var todayPages: Int {
        let calendar = Calendar.current
        return book.readingLogs
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.pagesRead }
    }

    // MARK: - Mark as Finished

    private var markFinishedButton: some View {
        Button {
            let newPage = book.totalPages
            let oldPage = book.currentPage
            guard newPage != oldPage else { return }
            let log = ReadingLog(fromPage: oldPage, toPage: newPage)
            log.book = book
            modelContext.insert(log)
            book.currentPage = newPage
            book.lastReadDate = Date()
            book.dateFinished = Date()
            HapticManager.bookFinished()
            showCelebration = true
            ReviewManager.recordBookFinished()
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
                        Image(systemName: note.noteType.icon)
                            .font(.caption2)
                            .foregroundStyle(note.noteType == .quote ? .orange : book.coverColor.color)
                        if note.page > 0 {
                            Text("p.\(note.page)")
                                .font(.caption2.bold())
                                .foregroundStyle(book.coverColor.color)
                        }
                        if note.noteType == .quote {
                            Text("\"\(note.content)\"")
                                .font(.caption)
                                .italic()
                                .lineLimit(2)
                        } else {
                            Text(note.content)
                                .font(.caption)
                                .lineLimit(2)
                        }
                        Spacer()
                        if note.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
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
        modelContext.delete(log)

        // Recalculate currentPage from remaining logs
        let remainingMax = book.readingLogs
            .filter { $0.id != log.id }
            .max(by: { $0.toPage < $1.toPage })?.toPage ?? 0
        book.currentPage = remainingMax

        HapticManager.tap()
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
