import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct JSONImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingBooks: [Book]

    @State private var importState: ImportState = .instructions
    @State private var parsedBooks: [ImportedBook] = []
    @State private var selectedBooks: Set<String> = []
    @State private var importError: String?
    @State private var importedCount = 0
    @State private var showingFilePicker = false
    @State private var skipDuplicates = true

    enum ImportState {
        case instructions, preview, importing, success, error
    }

    struct ImportedBook: Identifiable {
        let id: String
        let title: String
        let author: String
        let genre: String
        let totalPages: Int
        let currentPage: Int
        let dateAdded: Date?
        let lastReadDate: Date?
        let rating: Int?
        let review: String?
        let isFinished: Bool
        let bookType: BookType
        let isDuplicate: Bool
        let logs: [[String: Any]]
        let notes: [[String: Any]]
        let sessions: [[String: Any]]
        let chapters: [[String: Any]]
    }

    var body: some View {
        NavigationStack {
            Group {
                switch importState {
                case .instructions:
                    instructionsView
                case .preview:
                    previewView
                case .importing:
                    ProgressView("Importing...")
                        .padding()
                case .success:
                    successView
                case .error:
                    errorView
                }
            }
            .navigationTitle("Import Data")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    // MARK: - Instructions

    private var instructionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Import from JSON")
                .font(.title2.bold())

            Text("Import books from an æstel JSON export file. Your existing data will not be overwritten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingFilePicker = true
            } label: {
                Label("Choose JSON File", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
    }

    // MARK: - Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            // Stats bar
            HStack {
                Text("\(parsedBooks.count) books found")
                    .font(.subheadline.bold())
                Spacer()
                Toggle("Skip duplicates", isOn: $skipDuplicates)
                    .font(.caption)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: skipDuplicates) { _, skip in
                        if skip {
                            let dupeIDs = Set(parsedBooks.filter(\.isDuplicate).map(\.id))
                            selectedBooks.subtract(dupeIDs)
                        }
                    }
            }
            .padding()

            List {
                ForEach(displayedBooks) { book in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(book.title)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                if book.isDuplicate {
                                    Text("Duplicate")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(.orange, in: Capsule())
                                }
                            }
                            Text("\(book.author) · \(book.totalPages) pages · \(book.isFinished ? "Finished" : "\(Int(Double(book.currentPage) / max(Double(book.totalPages), 1) * 100))%")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: selectedBooks.contains(book.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedBooks.contains(book.id) ? .blue : .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedBooks.contains(book.id) {
                            selectedBooks.remove(book.id)
                        } else {
                            selectedBooks.insert(book.id)
                        }
                    }
                }
            }

            Button {
                performImport()
            } label: {
                Text("Import \(selectedBooks.count) Books")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedBooks.isEmpty)
            .padding()
        }
    }

    private var displayedBooks: [ImportedBook] {
        if skipDuplicates {
            return parsedBooks.filter { !$0.isDuplicate }
        }
        return parsedBooks
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Import Complete")
                .font(.title2.bold())

            Text("Successfully imported \(importedCount) books")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Import Failed")
                .font(.title2.bold())

            Text(importError ?? "Unknown error")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                importState = .instructions
                importError = nil
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Logic

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Cannot access the selected file"
                importState = .error
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                try parseJSON(data)
                // Auto-select non-duplicates
                selectedBooks = Set(parsedBooks.filter { !$0.isDuplicate }.map(\.id))
                importState = .preview
            } catch {
                importError = error.localizedDescription
                importState = .error
            }

        case .failure(let error):
            importError = error.localizedDescription
            importState = .error
        }
    }

    private func parseJSON(_ data: Data) throws {
        guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ImportError.invalidFormat
        }

        let dateFormatter = ISO8601DateFormatter()
        let existingTitles = Set(existingBooks.map { $0.title.lowercased() + "|" + $0.author.lowercased() })

        parsedBooks = array.compactMap { dict -> ImportedBook? in
            guard let title = dict["title"] as? String, !title.isEmpty else { return nil }
            let author = (dict["author"] as? String) ?? ""
            let totalPages = (dict["totalPages"] as? Int) ?? 0
            let currentPage = (dict["currentPage"] as? Int) ?? 0
            let finished = (dict["finished"] as? Bool) ?? false
            let genre = (dict["genre"] as? String) ?? ""
            let rating = dict["rating"] as? Int
            let review = dict["review"] as? String

            let dateAdded: Date? = (dict["dateAdded"] as? String).flatMap { dateFormatter.date(from: $0) }
            let lastReadDate: Date? = (dict["lastReadDate"] as? String).flatMap { dateFormatter.date(from: $0) }

            let isDuplicate = existingTitles.contains(title.lowercased() + "|" + author.lowercased())
            let bookTypeStr = (dict["bookType"] as? String) ?? "physical"
            let bookType = BookType(rawValue: bookTypeStr) ?? .physical

            return ImportedBook(
                id: UUID().uuidString,
                title: title,
                author: author,
                genre: genre,
                totalPages: totalPages,
                currentPage: currentPage,
                dateAdded: dateAdded,
                lastReadDate: lastReadDate,
                rating: rating,
                review: review,
                isFinished: finished,
                bookType: bookType,
                isDuplicate: isDuplicate,
                logs: (dict["readingLogs"] as? [[String: Any]]) ?? [],
                notes: (dict["notes"] as? [[String: Any]]) ?? [],
                sessions: (dict["sessions"] as? [[String: Any]]) ?? [],
                chapters: (dict["chapters"] as? [[String: Any]]) ?? []
            )
        }
    }

    private func performImport() {
        importState = .importing
        let dateFormatter = ISO8601DateFormatter()
        var count = 0

        let booksToImport = parsedBooks.filter { selectedBooks.contains($0.id) }

        for imported in booksToImport {
            let safeTotal = max(imported.totalPages, 0)
            let safeCurrent = max(min(imported.currentPage, safeTotal), 0)
            let book = Book(
                title: imported.title,
                author: imported.author,
                totalPages: safeTotal,
                bookType: imported.bookType
            )
            book.currentPage = safeCurrent
            book.genre = imported.genre
            book.rating = imported.rating
            book.review = imported.review
            if let dateAdded = imported.dateAdded { book.dateAdded = dateAdded }
            if let lastRead = imported.lastReadDate { book.lastReadDate = lastRead }
            if imported.isFinished { book.dateFinished = imported.lastReadDate }

            modelContext.insert(book)

            // Import reading logs
            for logDict in imported.logs {
                let fromPage = (logDict["fromPage"] as? Int) ?? 0
                let toPage = (logDict["toPage"] as? Int) ?? 0
                let log = ReadingLog(fromPage: fromPage, toPage: toPage)
                if let dateStr = logDict["date"] as? String, let date = dateFormatter.date(from: dateStr) {
                    log.date = date
                }
                log.pagesRead = (logDict["pagesRead"] as? Int) ?? max(toPage - fromPage, 0)
                log.book = book
                modelContext.insert(log)
            }

            // Import notes
            for noteDict in imported.notes {
                let content = (noteDict["content"] as? String) ?? ""
                let page = (noteDict["page"] as? Int) ?? 0
                let typeStr = (noteDict["type"] as? String) ?? "thought"
                let noteType = NoteType(rawValue: typeStr) ?? .thought
                let note = BookNote(content: content, page: page, noteType: noteType)
                note.isFavorite = (noteDict["isFavorite"] as? Bool) ?? false
                if let dateStr = noteDict["dateCreated"] as? String, let date = dateFormatter.date(from: dateStr) {
                    note.dateCreated = date
                }
                note.book = book
                modelContext.insert(note)
            }

            // Import sessions
            for sessionDict in imported.sessions {
                let sPage = (sessionDict["startPage"] as? Int) ?? 0
                let session = ReadingSession(startPage: sPage)
                session.durationSeconds = (sessionDict["durationSeconds"] as? Int) ?? 0
                session.endPage = (sessionDict["endPage"] as? Int) ?? 0
                if let startStr = sessionDict["startTime"] as? String,
                   let startTime = dateFormatter.date(from: startStr) {
                    session.startTime = startTime
                }
                if let endStr = sessionDict["endTime"] as? String {
                    session.endTime = dateFormatter.date(from: endStr)
                }
                session.book = book
                modelContext.insert(session)
            }

            // Import chapters
            for (index, chapterDict) in imported.chapters.enumerated() {
                let name = (chapterDict["name"] as? String) ?? ""
                let startPage = (chapterDict["startPage"] as? Int) ?? 0
                let endPage = (chapterDict["endPage"] as? Int) ?? 0
                let chapter = Chapter(name: name, startPage: startPage, endPage: endPage)
                chapter.sortOrder = index
                chapter.book = book
                modelContext.insert(chapter)
            }

            count += 1
        }

        importedCount = count
        importState = .success
        HapticManager.notification(.success)
    }

    enum ImportError: LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat: String(localized: "The file is not a valid æstel JSON export")
            }
        }
    }
}
