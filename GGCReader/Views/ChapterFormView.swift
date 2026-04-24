import SwiftUI
import SwiftData

struct ChapterFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let book: Book
    var chapterToEdit: Chapter?
    var nextSortOrder: Int = 0

    @State private var name = ""
    @State private var startPage = ""
    @State private var endPage = ""

    private var isEditing: Bool { chapterToEdit != nil }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Int(startPage) ?? 0) > 0 &&
        (Int(endPage) ?? 0) > 0 &&
        (Int(startPage) ?? 0) <= (Int(endPage) ?? 0) &&
        (Int(endPage) ?? 0) <= book.totalPages
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Chapter Info") {
                    TextField("Chapter Name", text: $name)
                    TextField("Start Page", text: $startPage)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("End Page", text: $endPage)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                if let start = Int(startPage), let end = Int(endPage), end >= start {
                    Section("Summary") {
                        LabeledContent("Pages", value: "\(end - start + 1)")
                        if end > book.totalPages {
                            Label("End page exceeds book total (\(book.totalPages))", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Chapter" : "Add Chapter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveChapter()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let chapter = chapterToEdit {
                    name = chapter.name
                    startPage = String(chapter.startPage)
                    endPage = String(chapter.endPage)
                }
            }
        }
    }

    private func saveChapter() {
        guard let start = Int(startPage), let end = Int(endPage) else { return }

        if let chapter = chapterToEdit {
            chapter.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            chapter.startPage = start
            chapter.endPage = end
        } else {
            let chapter = Chapter(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                startPage: start,
                endPage: end,
                sortOrder: nextSortOrder
            )
            chapter.book = book
            modelContext.insert(chapter)
        }
        dismiss()
    }
}
