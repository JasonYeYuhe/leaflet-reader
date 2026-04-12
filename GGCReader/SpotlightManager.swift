#if os(iOS) || os(macOS)
import CoreSpotlight
import SwiftData

@MainActor
enum SpotlightManager {
    private static let domainID = "com.jason.ggcreader.books"

    /// Index a single book in Spotlight
    static func indexBook(_ book: Book) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = book.title
        attributeSet.contentDescription = [book.author, book.genre].filter { !$0.isEmpty }.joined(separator: " · ")
        attributeSet.keywords = [book.title, book.author, book.genre, book.publisher].filter { !$0.isEmpty }

        let item = CSSearchableItem(
            uniqueIdentifier: book.id.uuidString,
            domainIdentifier: domainID,
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                print("[Spotlight] Index error: \(error)")
            }
        }
    }

    /// Remove a book from Spotlight index
    static func removeBook(_ book: Book) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [book.id.uuidString]) { error in
            if let error {
                print("[Spotlight] Remove error: \(error)")
            }
        }
    }

    /// Re-index all books (call on app launch or data restore)
    static func reindexAll(books: [Book]) {
        // Clear existing index
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainID]) { error in
            if let error {
                print("[Spotlight] Clear error: \(error)")
                return
            }

            // Re-add all
            let items = books.map { book -> CSSearchableItem in
                let attrs = CSSearchableItemAttributeSet(contentType: .content)
                attrs.title = book.title
                attrs.contentDescription = [book.author, book.genre].filter { !$0.isEmpty }.joined(separator: " · ")
                attrs.keywords = [book.title, book.author, book.genre, book.publisher].filter { !$0.isEmpty }

                let item = CSSearchableItem(
                    uniqueIdentifier: book.id.uuidString,
                    domainIdentifier: domainID,
                    attributeSet: attrs
                )
                item.expirationDate = .distantFuture
                return item
            }

            guard !items.isEmpty else { return }
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error {
                    print("[Spotlight] Reindex error: \(error)")
                }
            }
        }
    }
}
#endif
