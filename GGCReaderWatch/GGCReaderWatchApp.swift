import SwiftUI
import SwiftData

@main
struct GGCReaderWatchApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try SharedModelContainer.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchBookListView()
        }
        .modelContainer(modelContainer)
    }
}
