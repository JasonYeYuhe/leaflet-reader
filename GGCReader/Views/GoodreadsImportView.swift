import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct GoodreadsImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var parsedBooks: [GoodreadsBook] = []
    @State private var selectedShelves: Set<String> = ["read", "currently-reading", "to-read"]
    @State private var errorMessage: String?
    @State private var showingFilePicker = false
    @State private var importCount = 0
    @State private var importDone = false

    private var availableShelves: [String] {
        Array(Set(parsedBooks.map(\.shelf))).sorted()
    }

    private var filteredBooks: [GoodreadsBook] {
        parsedBooks.filter { selectedShelves.contains($0.shelf) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if parsedBooks.isEmpty && !importDone {
                    instructionsView
                } else if importDone {
                    successView
                } else {
                    previewView
                }
            }
            .navigationTitle("Import from Goodreads")
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
                allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFilePicked(result)
            }
        }
    }

    // MARK: - Instructions

    private var instructionsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Import your Goodreads library")
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 12) {
                instructionStep(number: 1, text: "Go to goodreads.com/review/import")
                instructionStep(number: 2, text: "Click \"Export Library\" at the top")
                instructionStep(number: 3, text: "Download the CSV file")
                instructionStep(number: 4, text: "Open it here")
            }
            .padding(.horizontal, 24)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                showingFilePicker = true
            } label: {
                Label("Choose CSV File", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(.blue.opacity(0.12), in: Circle())
                .foregroundStyle(.blue)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Preview

    private var previewView: some View {
        List {
            Section {
                ForEach(availableShelves, id: \.self) { shelf in
                    let count = parsedBooks.filter { $0.shelf == shelf }.count
                    Toggle(isOn: Binding(
                        get: { selectedShelves.contains(shelf) },
                        set: { enabled in
                            if enabled {
                                selectedShelves.insert(shelf)
                            } else {
                                selectedShelves.remove(shelf)
                            }
                        }
                    )) {
                        HStack {
                            Text(shelfDisplayName(shelf))
                            Spacer()
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Shelves to Import")
            }

            Section {
                ForEach(Array(filteredBooks.prefix(50).enumerated()), id: \.offset) { _, book in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(book.author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if book.pages > 0 {
                            Text("\(book.pages)p")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(shelfBadge(book.shelf))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
                if filteredBooks.count > 50 {
                    Text("and \(filteredBooks.count - 50) more...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Preview (\(filteredBooks.count) books)")
            }

            Section {
                Button {
                    performImport()
                } label: {
                    Label("Import \(filteredBooks.count) Books", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .disabled(filteredBooks.isEmpty)
            }
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Import Complete!")
                .font(.title2.bold())
            Text("\(importCount) books imported successfully")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
            Spacer()
        }
    }

    // MARK: - Actions

    private func handleFilePicked(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Could not access the file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                parsedBooks = try GoodreadsImporter.parse(csv: content)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func performImport() {
        importCount = GoodreadsImporter.importBooks(filteredBooks, into: modelContext)
        importDone = true
    }

    // MARK: - Helpers

    private func shelfDisplayName(_ shelf: String) -> String {
        switch shelf {
        case "read": String(localized: "Read")
        case "currently-reading": String(localized: "Currently Reading")
        case "to-read": String(localized: "To Read")
        default: shelf
        }
    }

    private func shelfBadge(_ shelf: String) -> String {
        switch shelf {
        case "read": "✓"
        case "currently-reading": "📖"
        case "to-read": "📋"
        default: shelf
        }
    }
}
