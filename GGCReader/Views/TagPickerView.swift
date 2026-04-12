import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var newTagName = ""
    @State private var newTagColor: CoverColor = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Existing tags
            if !allTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(allTags) { tag in
                        let isSelected = book.tags.contains { $0.id == tag.id }
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.caption2)
                                Text(tag.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isSelected ? tag.color.color.opacity(0.2) : Color.gray.opacity(0.1), in: Capsule())
                            .foregroundStyle(isSelected ? tag.color.color : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Add new tag
            HStack(spacing: 8) {
                TextField("New tag...", text: $newTagName)
                    .font(.caption)
                    #if os(iOS)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .frame(maxWidth: 140)

                // Mini color picker
                Menu {
                    ForEach([CoverColor.blue, .green, .orange, .red, .purple, .teal, .pink, .indigo], id: \.self) { color in
                        Button {
                            newTagColor = color
                        } label: {
                            Label(color.displayName, systemImage: newTagColor == color ? "checkmark.circle.fill" : "circle.fill")
                        }
                    }
                } label: {
                    Circle()
                        .fill(newTagColor.color)
                        .frame(width: 20, height: 20)
                }

                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func toggleTag(_ tag: Tag) {
        if let index = book.tags.firstIndex(where: { $0.id == tag.id }) {
            book.tags.remove(at: index)
        } else {
            book.tags.append(tag)
        }
        HapticManager.selection()
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        // Check if tag already exists
        if let existing = allTags.first(where: { $0.name.lowercased() == name.lowercased() }) {
            if !book.tags.contains(where: { $0.id == existing.id }) {
                book.tags.append(existing)
            }
        } else {
            let tag = Tag(name: name, color: newTagColor)
            modelContext.insert(tag)
            book.tags.append(tag)
        }

        newTagName = ""
        HapticManager.tap()
    }
}
