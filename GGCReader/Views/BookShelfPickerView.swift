import SwiftUI
import SwiftData

struct BookShelfPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Bookshelf.sortOrder) private var allShelves: [Bookshelf]
    @Bindable var book: Book

    var body: some View {
        NavigationStack {
            List {
                if allShelves.isEmpty {
                    ContentUnavailableView {
                        Label("No Shelves", systemImage: "books.vertical")
                    } description: {
                        Text("Create shelves first from the Books tab")
                    }
                }

                ForEach(allShelves) { shelf in
                    let isOnShelf = book.shelves.contains { $0.id == shelf.id }
                    Button {
                        if isOnShelf {
                            book.shelves.removeAll { $0.id == shelf.id }
                        } else {
                            book.shelves.append(shelf)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: shelf.icon)
                                .foregroundStyle(colorFor(shelf.colorName))
                                .frame(width: 28)
                            Text(shelf.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if isOnShelf {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Shelf")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
