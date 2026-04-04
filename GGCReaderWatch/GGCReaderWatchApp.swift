import SwiftUI
import SwiftData

@main
struct GGCReaderWatchApp: App {
    let modelContainer: ModelContainer?

    init() {
        do {
            modelContainer = try SharedModelContainer.create()
        } catch {
            print("[GGCReaderWatch] Failed to create ModelContainer: \(error)")
            modelContainer = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                WatchBookListView()
                    .modelContainer(modelContainer)
            } else {
                ContentUnavailableView(
                    "Unable to Load Data",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app or check your iCloud settings.")
                )
            }
        }
    }
}
