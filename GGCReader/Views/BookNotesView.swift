import SwiftUI
import SwiftData

struct BookNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book
    @State private var showingAddNote = false
    @State private var showingPaywall = false
    @State private var filterType: NoteType?
    @State private var showFavoritesOnly = false
    var storeManager = StoreManager.shared

    private var canAddNote: Bool {
        storeManager.isPro || book.notes.count < StoreManager.freeNoteLimit
    }

    private var filteredNotes: [BookNote] {
        var notes = book.notes.sorted { $0.dateCreated > $1.dateCreated }
        if let filterType {
            notes = notes.filter { $0.noteType == filterType }
        }
        if showFavoritesOnly {
            notes = notes.filter { $0.isFavorite }
        }
        return notes
    }

    private var quoteCount: Int {
        book.notes.filter { $0.noteType == .quote }.count
    }

    private var thoughtCount: Int {
        book.notes.filter { $0.noteType == .thought }.count
    }

    var body: some View {
        NavigationStack {
            List {
                if !book.notes.isEmpty {
                    filterSection
                }

                if filteredNotes.isEmpty {
                    ContentUnavailableView {
                        Label(showFavoritesOnly ? "No Favorites" : "No Notes", systemImage: showFavoritesOnly ? "heart" : "note.text")
                    } description: {
                        Text(showFavoritesOnly ? "Tap the heart icon on a note to save it" : "Add notes, highlights, or thoughts while reading")
                    }
                } else {
                    ForEach(filteredNotes) { note in
                        noteRow(note)
                    }
                    .onDelete(perform: deleteNotes)
                }
            }
            .navigationTitle("Notes")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if canAddNote {
                            showingAddNote = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteSheet(book: book)
            }
        }
    }

    // MARK: - Filter

    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All (\(book.notes.count))", isSelected: filterType == nil && !showFavoritesOnly) {
                        filterType = nil
                        showFavoritesOnly = false
                    }
                    FilterChip(label: "\(NoteType.thought.displayName) (\(thoughtCount))", icon: NoteType.thought.icon, isSelected: filterType == .thought) {
                        filterType = .thought
                        showFavoritesOnly = false
                    }
                    FilterChip(label: "\(NoteType.quote.displayName) (\(quoteCount))", icon: NoteType.quote.icon, isSelected: filterType == .quote) {
                        filterType = .quote
                        showFavoritesOnly = false
                    }
                    FilterChip(label: "Favorites", icon: "heart.fill", isSelected: showFavoritesOnly) {
                        showFavoritesOnly = true
                        filterType = nil
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    // MARK: - Note Row

    private func noteRow(_ note: BookNote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: note.noteType.icon)
                    .font(.caption)
                    .foregroundStyle(note.noteType == .quote ? .orange : book.coverColor.color)
                if note.page > 0 {
                    Text("p.\(note.page)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(book.coverColor.color, in: Capsule())
                }
                Spacer()
                Button {
                    withAnimation { note.isFavorite.toggle() }
                    HapticManager.selection()
                } label: {
                    Image(systemName: note.isFavorite ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundStyle(note.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }

            if note.noteType == .quote {
                Text("\"\(note.content)\"")
                    .font(.body)
                    .italic()
            } else {
                Text(note.content)
                    .font(.body)
            }

            Text(note.dateCreated.formatted(.dateTime.month().day().hour().minute()))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredNotes[index])
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1), in: Capsule())
            .foregroundStyle(isSelected ? .white : .accentColor)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Note Sheet

struct AddNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book

    @State private var content = ""
    @State private var page = ""
    @State private var selectedType: NoteType = .thought

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(NoteType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Page", text: $page)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                } header: {
                    Text(selectedType == .quote ? "Quote" : "Your Thoughts")
                } footer: {
                    if selectedType == .quote {
                        Text("Copy the exact text from the book")
                    }
                }
            }
            .navigationTitle("Add Note")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addNote()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .bold()
                }
            }
            .onAppear {
                page = String(book.currentPage)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addNote() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = BookNote(content: trimmed, page: Int(page) ?? 0, noteType: selectedType)
        note.book = book
        modelContext.insert(note)
        HapticManager.tap()
        dismiss()
    }
}
