import Foundation
import SwiftData

struct GoodreadsBook {
    let title: String
    let author: String
    let isbn: String
    let pages: Int
    let dateRead: Date?
    let dateAdded: Date?
    let shelf: String // "read", "currently-reading", "to-read"
    let publisher: String
}

enum GoodreadsImporter {
    enum ImportError: LocalizedError {
        case invalidFormat
        case noBooks

        var errorDescription: String? {
            switch self {
            case .invalidFormat: String(localized: "Invalid CSV format. Make sure this is a Goodreads export file.")
            case .noBooks: String(localized: "No books found in the file.")
            }
        }
    }

    static func parse(csv: String) throws -> [GoodreadsBook] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { throw ImportError.invalidFormat }

        // Parse header to find column indices
        let header = parseCSVRow(lines[0])
        guard let titleIdx = header.firstIndex(of: "Title"),
              let authorIdx = header.firstIndex(of: "Author") else {
            throw ImportError.invalidFormat
        }

        let isbnIdx = header.firstIndex(of: "ISBN13") ?? header.firstIndex(of: "ISBN")
        let pagesIdx = header.firstIndex(of: "Number of Pages")
        let dateReadIdx = header.firstIndex(of: "Date Read")
        let dateAddedIdx = header.firstIndex(of: "Date Added")
        let shelfIdx = header.firstIndex(of: "Exclusive Shelf")
        let publisherIdx = header.firstIndex(of: "Publisher")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let altDateFormatter = DateFormatter()
        altDateFormatter.dateFormat = "yyyy-MM-dd"

        var books: [GoodreadsBook] = []

        for i in 1..<lines.count {
            let row = parseCSVRow(lines[i])
            guard row.count > max(titleIdx, authorIdx) else { continue }

            let title = row[titleIdx].trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }

            let author = row[authorIdx].trimmingCharacters(in: .whitespaces)

            var isbn = ""
            if let idx = isbnIdx, row.count > idx {
                // Goodreads uses Excel formula notation: ="9780441013593"
                // After CSV parsing quotes are stripped, leaving =9780441013593
                isbn = row[idx]
                    .replacingOccurrences(of: "=\"", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "=", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }

            var pages = 0
            if let idx = pagesIdx, row.count > idx {
                pages = Int(row[idx].trimmingCharacters(in: .whitespaces)) ?? 0
            }

            var dateRead: Date?
            if let idx = dateReadIdx, row.count > idx {
                let dateStr = row[idx].trimmingCharacters(in: .whitespaces)
                dateRead = dateFormatter.date(from: dateStr) ?? altDateFormatter.date(from: dateStr)
            }

            var dateAdded: Date?
            if let idx = dateAddedIdx, row.count > idx {
                let dateStr = row[idx].trimmingCharacters(in: .whitespaces)
                dateAdded = dateFormatter.date(from: dateStr) ?? altDateFormatter.date(from: dateStr)
            }

            var shelf = ""
            if let idx = shelfIdx, row.count > idx {
                shelf = row[idx].trimmingCharacters(in: .whitespaces)
            }

            var publisher = ""
            if let idx = publisherIdx, row.count > idx {
                publisher = row[idx].trimmingCharacters(in: .whitespaces)
            }

            books.append(GoodreadsBook(
                title: title,
                author: author,
                isbn: isbn,
                pages: pages,
                dateRead: dateRead,
                dateAdded: dateAdded,
                shelf: shelf,
                publisher: publisher
            ))
        }

        guard !books.isEmpty else { throw ImportError.noBooks }
        return books
    }

    @MainActor
    static func importBooks(_ goodreadsBooks: [GoodreadsBook], into context: ModelContext) -> Int {
        // Fetch existing books for duplicate detection
        let existingBooks = (try? context.fetch(FetchDescriptor<Book>())) ?? []
        let existingTitles = Set(existingBooks.map { "\($0.title.lowercased())|\($0.author.lowercased())" })

        var imported = 0
        for gb in goodreadsBooks {
            // Skip duplicates by title+author
            let key = "\(gb.title.lowercased())|\(gb.author.lowercased())"
            guard !existingTitles.contains(key) else { continue }

            let book = Book(
                title: gb.title,
                author: gb.author,
                totalPages: gb.pages
            )
            book.isbn = gb.isbn
            book.publisher = gb.publisher
            if let dateAdded = gb.dateAdded {
                book.dateAdded = dateAdded
            }

            // Set progress based on shelf
            switch gb.shelf {
            case "read":
                book.currentPage = gb.pages > 0 ? gb.pages : 0
                book.lastReadDate = gb.dateRead ?? gb.dateAdded
            case "currently-reading":
                // Leave at page 0, user can update
                book.lastReadDate = gb.dateRead ?? gb.dateAdded
            default:
                // "to-read" or other shelves — just add the book
                break
            }

            context.insert(book)
            imported += 1
        }
        do { try context.save() } catch { print("[GoodreadsImporter] Failed to save: \(error)") }
        return imported
    }

    // MARK: - CSV Parser (handles quoted fields with commas)

    private static func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }
}
