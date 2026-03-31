import SwiftUI
import SwiftData

struct WatchBookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    @State private var crownValue: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ProgressRingView(
                    progress: book.progressPercentage,
                    color: book.coverColor.color,
                    lineWidth: 8,
                    size: 80
                )

                Text(book.title)
                    .font(.caption.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("Page \(book.currentPage) of \(book.totalPages)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let chapter = book.currentChapter {
                    Text(chapter.name)
                        .font(.caption2)
                        .foregroundStyle(book.coverColor.color)
                        .lineLimit(1)
                }

                Text("\(book.pagesRemaining) pages left")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 12) {
                    Button {
                        adjustPage(by: 1)
                    } label: {
                        Label("+1", systemImage: "plus")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        adjustPage(by: 5)
                    } label: {
                        Text("+5")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .tint(book.coverColor.color)

                    Button {
                        adjustPage(by: 10)
                    } label: {
                        Text("+10")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .tint(book.coverColor.color)
                }
            }
            .padding()
        }
        .onAppear {
            crownValue = Double(book.currentPage)
        }
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: Double(book.totalPages),
            by: 1,
            sensitivity: .medium
        )
        .onChange(of: crownValue) { _, newValue in
            let newPage = Int(newValue.rounded())
            if newPage != book.currentPage {
                let oldPage = book.currentPage
                book.currentPage = min(max(newPage, 0), book.totalPages)
                book.lastReadDate = Date()

                if book.currentPage > oldPage {
                    let log = ReadingLog(fromPage: oldPage, toPage: book.currentPage)
                    log.book = book
                    modelContext.insert(log)
                }
            }
        }
    }

    private func adjustPage(by delta: Int) {
        let oldPage = book.currentPage
        let newPage = min(max(oldPage + delta, 0), book.totalPages)
        if newPage != oldPage {
            book.currentPage = newPage
            book.lastReadDate = Date()
            crownValue = Double(newPage)

            if newPage > oldPage {
                let log = ReadingLog(fromPage: oldPage, toPage: newPage)
                log.book = book
                modelContext.insert(log)
            }
        }
    }
}
