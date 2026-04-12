import SwiftData

struct SharedModelContainer {
    static func create() throws -> ModelContainer {
        let schema = Schema([Book.self, Chapter.self, ReadingLog.self, BookNote.self, ReadingSession.self, Bookshelf.self, ReadingChallenge.self])
        #if os(watchOS)
        let config = ModelConfiguration(
            "GGCReader",
            schema: schema,
            cloudKitDatabase: .none
        )
        #else
        let config = ModelConfiguration(
            "GGCReader",
            schema: schema,
            cloudKitDatabase: .automatic
        )
        #endif
        return try ModelContainer(for: schema, configurations: [config])
    }
}
