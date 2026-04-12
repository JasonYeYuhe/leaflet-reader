import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    var storeManager = StoreManager.shared
    @State private var showingPaywall = false
    @State private var csvFile: CSVFile?
    @State private var jsonFile: JSONExportFile?
    @State private var showingExportError = false
    @State private var showingGoodreadsImport = false
    @State private var showingJSONImport = false

    var body: some View {
        List {
            proSection
            quotesSection
            exportSection
            #if os(iOS)
            appIconSection
            #endif
            aboutSection
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Pro Status

    private var proSection: some View {
        Section {
            if storeManager.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("æstel Pro")
                            .font(.headline)
                        Text("All features unlocked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Unlimited books, all badges & more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - App Icon

    #if os(iOS)
    private var currentIconName: String? {
        UIApplication.shared.alternateIconName
    }

    private var appIconSection: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(AppIconOption.allCases) { option in
                    appIconItem(option)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("App Icon")
        }
    }

    private func appIconItem(_ option: AppIconOption) -> some View {
        let isSelected = currentIconName == option.iconName
        let isLocked = option != .blue && !storeManager.isPro
        return VStack(spacing: 6) {
            Image(uiImage: option.preview)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .overlay {
                    if isLocked {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.black.opacity(0.3))
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white)
                            .font(.caption)
                    }
                }
                .shadow(radius: isSelected ? 4 : 1)

            Text(option.displayName)
                .font(.caption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            setIcon(option)
        }
    }

    private func setIcon(_ option: AppIconOption) {
        guard option == .blue || storeManager.isPro else {
            showingPaywall = true
            return
        }
        HapticManager.selection()
        UIApplication.shared.setAlternateIconName(option.iconName) { error in
            if error != nil {
                HapticManager.notification(.error)
            }
        }
    }
    #endif

    // MARK: - Quotes Collection

    private var quotesSection: some View {
        Section {
            NavigationLink {
                QuotesCollectionView()
            } label: {
                Label("Quotes & Favorites", systemImage: "text.quote")
            }
        }
    }

    // MARK: - Export Data

    private var exportSection: some View {
        Section {
            Button {
                generateCSV()
            } label: {
                Label("Export CSV", systemImage: "tablecells")
            }
            if let csvFile {
                ShareLink(item: csvFile, preview: SharePreview("æstel Export.csv", image: Image(systemName: "tablecells"))) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                }
            }
            Button {
                generateJSON()
            } label: {
                Label("Export JSON (Full Data)", systemImage: "doc.text")
            }
            if let jsonFile {
                ShareLink(item: jsonFile, preview: SharePreview("æstel Export.json", image: Image(systemName: "doc.text"))) {
                    Label("Share JSON", systemImage: "square.and.arrow.up")
                }
            }
            Button {
                showingGoodreadsImport = true
            } label: {
                Label("Import from Goodreads", systemImage: "arrow.down.doc")
            }
            .sheet(isPresented: $showingGoodreadsImport) {
                GoodreadsImportView()
            }
            Button {
                showingJSONImport = true
            } label: {
                Label("Import from JSON Backup", systemImage: "arrow.down.doc.fill")
            }
            .sheet(isPresented: $showingJSONImport) {
                JSONImportView()
            }
        } header: {
            Text("Data")
        }
    }

    private func generateCSV() {
        var csv = "Title,Author,Genre,Total Pages,Current Page,Progress,Date Added,Finished,Rating\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for book in books {
            let title = book.title.replacingOccurrences(of: ",", with: ";")
            let author = book.author.replacingOccurrences(of: ",", with: ";")
            let genre = book.genre.replacingOccurrences(of: ",", with: ";")
            let progress = String(format: "%.0f%%", book.progressPercentage * 100)
            let added = dateFormatter.string(from: book.dateAdded)
            let ratingStr = book.rating.map { String($0) } ?? ""
            csv += "\(title),\(author),\(genre),\(book.totalPages),\(book.currentPage),\(progress),\(added),\(book.isFinished ? "Yes" : "No"),\(ratingStr)\n"
        }

        csvFile = CSVFile(content: csv)
    }

    private func generateJSON() {
        let dateFormatter = ISO8601DateFormatter()
        let export: [[String: Any]] = books.map { book in
            var dict: [String: Any] = [
                "title": book.title,
                "author": book.author,
                "genre": book.genre,
                "totalPages": book.totalPages,
                "currentPage": book.currentPage,
                "progress": book.progressPercentage,
                "dateAdded": dateFormatter.string(from: book.dateAdded),
                "finished": book.isFinished,
                "bookType": book.bookType.rawValue
            ]
            if let lastRead = book.lastReadDate {
                dict["lastReadDate"] = dateFormatter.string(from: lastRead)
            }
            if let rating = book.rating {
                dict["rating"] = rating
            }
            if let review = book.review {
                dict["review"] = review
            }
            dict["readingLogs"] = book.readingLogs
                .sorted { $0.date > $1.date }
                .map { log in
                    [
                        "date": dateFormatter.string(from: log.date),
                        "fromPage": log.fromPage,
                        "toPage": log.toPage,
                        "pagesRead": log.pagesRead
                    ] as [String: Any]
                }
            dict["notes"] = book.notes
                .sorted { $0.dateCreated > $1.dateCreated }
                .map { note in
                    let n: [String: Any] = [
                        "content": note.content,
                        "page": note.page,
                        "dateCreated": dateFormatter.string(from: note.dateCreated),
                        "type": note.noteType.rawValue,
                        "isFavorite": note.isFavorite
                    ]
                    return n
                }
            dict["sessions"] = book.sessions
                .sorted { $0.startTime > $1.startTime }
                .map { session in
                    var s: [String: Any] = [
                        "startTime": dateFormatter.string(from: session.startTime),
                        "durationSeconds": session.durationSeconds,
                        "startPage": session.startPage,
                        "endPage": session.endPage
                    ]
                    if let endTime = session.endTime {
                        s["endTime"] = dateFormatter.string(from: endTime)
                    }
                    return s
                }
            dict["chapters"] = book.chapters
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { chapter in
                    [
                        "name": chapter.name,
                        "startPage": chapter.startPage,
                        "endPage": chapter.endPage
                    ] as [String: Any]
                }
            return dict
        }

        if let data = try? JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .sortedKeys]) {
            jsonFile = JSONExportFile(data: data)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - App Icon Options

// MARK: - CSV Export

struct CSVFile: Transferable {
    let content: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.content.utf8)
        }
    }
}

struct JSONExportFile: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { file in
            file.data
        }
    }
}

#if os(iOS)
enum AppIconOption: String, CaseIterable, Identifiable {
    case blue = "AppIcon"
    case green = "AppIconGreen"
    case purple = "AppIconPurple"
    case orange = "AppIconOrange"
    case teal = "AppIconTeal"
    case dark = "AppIconDark"

    var id: String { rawValue }

    /// nil means default icon
    var iconName: String? {
        self == .blue ? nil : rawValue
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .blue: "Blue"
        case .green: "Green"
        case .purple: "Purple"
        case .orange: "Orange"
        case .teal: "Teal"
        case .dark: "Dark"
        }
    }

    var preview: UIImage {
        // Try to load from asset catalog
        if let img = UIImage(named: rawValue) {
            return img
        }
        // Fallback: solid color
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let color: UIColor = switch self {
            case .blue: .systemBlue
            case .green: .systemGreen
            case .purple: .systemPurple
            case .orange: .systemOrange
            case .teal: .systemTeal
            case .dark: .darkGray
            }
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 24).fill()
        }
    }
}
#endif
