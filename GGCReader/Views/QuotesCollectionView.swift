import SwiftUI
import SwiftData

struct QuotesCollectionView: View {
    @Query(sort: \BookNote.dateCreated, order: .reverse) private var allNotes: [BookNote]
    @State private var filterMode: FilterMode = .favorites
    @State private var noteToShare: BookNote?

    enum FilterMode: String, CaseIterable {
        case favorites, allQuotes

        var label: String {
            switch self {
            case .favorites: String(localized: "Favorites")
            case .allQuotes: String(localized: "All Quotes")
            }
        }
    }

    private var displayedNotes: [BookNote] {
        switch filterMode {
        case .favorites:
            return allNotes.filter { $0.isFavorite }
        case .allQuotes:
            return allNotes.filter { $0.noteType == .quote }
        }
    }

    var body: some View {
        List {
            Picker("Filter", selection: $filterMode) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            if displayedNotes.isEmpty {
                ContentUnavailableView {
                    Label(filterMode == .favorites ? "No Favorites" : "No Quotes",
                          systemImage: filterMode == .favorites ? "heart" : "text.quote")
                } description: {
                    Text(filterMode == .favorites
                         ? "Tap the heart icon on any note to save it here"
                         : "Add quotes while reading to collect them here")
                }
            } else {
                ForEach(displayedNotes) { note in
                    quoteCard(note)
                }
            }
        }
        .navigationTitle("Quotes & Favorites")
        .sheet(item: $noteToShare) { note in
            QuoteShareSheet(note: note)
        }
    }

    private func quoteCard(_ note: BookNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if note.noteType == .quote {
                Text("\"\(note.content)\"")
                    .font(.body)
                    .italic()
            } else {
                Text(note.content)
                    .font(.body)
            }

            HStack {
                if let book = note.book {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed")
                            .font(.caption2)
                        Text(book.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
                if note.page > 0 {
                    Text("p.\(note.page)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: note.noteType.icon)
                    .font(.caption2)
                    .foregroundStyle(note.noteType == .quote ? .orange : .blue)
                if note.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading) {
            Button {
                noteToShare = note
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
}
