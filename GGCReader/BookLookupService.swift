import Foundation

struct BookLookupResult {
    var title: String
    var author: String
    var totalPages: Int
    var coverURL: URL?
    var publisher: String
    var isbn: String
}

actor BookLookupService {
    static let shared = BookLookupService()

    func lookup(isbn: String) async throws -> BookLookupResult {
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
        guard !cleanISBN.isEmpty else { throw LookupError.invalidISBN }
        // ISBN-10 may end in 'X' (check digit); ISBN-13 is all digits. Reject non-ISBN chars early.
        let prefix = cleanISBN.last == "X" ? String(cleanISBN.dropLast()) : cleanISBN
        guard !prefix.isEmpty, prefix.allSatisfy(\.isNumber) else {
            throw LookupError.invalidISBN
        }

        // Try Open Library first
        if let result = try? await lookupOpenLibrary(isbn: cleanISBN) {
            return result
        }

        // Fallback to Google Books
        if let result = try? await lookupGoogleBooks(isbn: cleanISBN) {
            return result
        }

        throw LookupError.notFound
    }

    // MARK: - Open Library

    private func lookupOpenLibrary(isbn: String) async throws -> BookLookupResult {
        guard let url = URL(string: "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data") else {
            throw LookupError.invalidISBN
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LookupError.networkError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let bookData = json["ISBN:\(isbn)"] as? [String: Any] else {
            throw LookupError.notFound
        }

        let title = bookData["title"] as? String ?? ""
        let authors = bookData["authors"] as? [[String: Any]] ?? []
        let author = authors.first?["name"] as? String ?? ""
        let pages = bookData["number_of_pages"] as? Int ?? 0
        let publishers = bookData["publishers"] as? [[String: Any]] ?? []
        let publisher = publishers.first?["name"] as? String ?? ""

        // Cover URL
        var coverURL: URL?
        if let cover = bookData["cover"] as? [String: Any],
           let medium = cover["medium"] as? String {
            coverURL = URL(string: medium)
        }

        guard !title.isEmpty else { throw LookupError.notFound }

        return BookLookupResult(
            title: title,
            author: author,
            totalPages: pages,
            coverURL: coverURL,
            publisher: publisher,
            isbn: isbn
        )
    }

    // MARK: - Google Books

    private func lookupGoogleBooks(isbn: String) async throws -> BookLookupResult {
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)&maxResults=1") else {
            throw LookupError.invalidISBN
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LookupError.networkError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]],
              let volumeInfo = items.first?["volumeInfo"] as? [String: Any] else {
            throw LookupError.notFound
        }

        let title = volumeInfo["title"] as? String ?? ""
        let authors = volumeInfo["authors"] as? [String] ?? []
        let author = authors.first ?? ""
        let pages = volumeInfo["pageCount"] as? Int ?? 0
        let publisher = volumeInfo["publisher"] as? String ?? ""

        var coverURL: URL?
        if let imageLinks = volumeInfo["imageLinks"] as? [String: Any],
           let thumbnail = imageLinks["thumbnail"] as? String {
            // Google Books uses http, convert to https
            coverURL = URL(string: thumbnail.replacingOccurrences(of: "http://", with: "https://"))
        }

        guard !title.isEmpty else { throw LookupError.notFound }

        return BookLookupResult(
            title: title,
            author: author,
            totalPages: pages,
            coverURL: coverURL,
            publisher: publisher,
            isbn: isbn
        )
    }

    // MARK: - Download Cover

    func downloadCover(from url: URL) async -> Data? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        return data
    }

    enum LookupError: LocalizedError {
        case invalidISBN
        case notFound
        case networkError

        var errorDescription: String? {
            switch self {
            case .invalidISBN: String(localized: "Invalid ISBN")
            case .notFound: String(localized: "Book not found. Try entering details manually.")
            case .networkError: String(localized: "Network error. Check your connection.")
            }
        }
    }
}
