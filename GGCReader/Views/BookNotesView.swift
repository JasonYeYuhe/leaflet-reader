import SwiftUI
import SwiftData

struct BookNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book
    @State private var showingAddNote = false
    @State private var newNoteContent = ""
    @State private var newNotePage = ""

    private var sortedNotes: [BookNote] {
        book.notes.sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        NavigationStack {
            List {
                if sortedNotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Notes", systemImage: "note.text")
                    } description: {
                        Text("Add notes, highlights, or thoughts while reading")
                    }
                } else {
                    ForEach(sortedNotes) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                if note.page > 0 {
                                    Text("p.\(note.page)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(book.coverColor.color, in: Capsule())
                                }
                                Spacer()
                                Text(note.dateCreated.formatted(.dateTime.month().day().hour().minute()))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(note.content)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
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
                        showingAddNote = true
                        newNotePage = String(book.currentPage)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Add Note", isPresented: $showingAddNote) {
                TextField("Your note...", text: $newNoteContent)
                TextField("Page (optional)", text: $newNotePage)
                Button("Add") { addNote() }
                Button("Cancel", role: .cancel) {
                    newNoteContent = ""
                    newNotePage = ""
                }
            }
        }
    }

    private func addNote() {
        guard !newNoteContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let note = BookNote(
            content: newNoteContent.trimmingCharacters(in: .whitespaces),
            page: Int(newNotePage) ?? 0
        )
        note.book = book
        modelContext.insert(note)
        newNoteContent = ""
        newNotePage = ""
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedNotes[index])
        }
    }
}
