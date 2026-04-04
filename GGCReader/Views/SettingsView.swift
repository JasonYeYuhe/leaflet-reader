import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    var storeManager = StoreManager.shared
    @State private var showingPaywall = false
    @State private var csvFile: CSVFile?
    @State private var showingExportError = false

    var body: some View {
        List {
            proSection
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

    // MARK: - Export Data

    private var exportSection: some View {
        Section {
            if let csvFile {
                ShareLink(item: csvFile, preview: SharePreview("æstel Export", image: Image(systemName: "tablecells"))) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                }
            }
            Button {
                generateCSV()
            } label: {
                Label("Export Reading Data", systemImage: "arrow.down.doc")
            }
        } header: {
            Text("Data")
        }
    }

    private func generateCSV() {
        var csv = "Title,Author,Total Pages,Current Page,Progress,Date Added,Finished\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for book in books {
            let title = book.title.replacingOccurrences(of: ",", with: ";")
            let author = book.author.replacingOccurrences(of: ",", with: ";")
            let progress = String(format: "%.0f%%", book.progressPercentage * 100)
            let added = dateFormatter.string(from: book.dateAdded)
            csv += "\(title),\(author),\(book.totalPages),\(book.currentPage),\(progress),\(added),\(book.isFinished ? "Yes" : "No")\n"
        }

        csvFile = CSVFile(content: csv)
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
