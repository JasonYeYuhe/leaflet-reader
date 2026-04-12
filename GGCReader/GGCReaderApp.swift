import SwiftUI
import SwiftData

@main
struct GGCReaderApp: App {
    let modelContainer: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            modelContainer = try SharedModelContainer.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // Start StoreKit transaction listener early
        _ = StoreManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear { updateWidgetData() }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                updateWidgetData()
            }
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
        }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }
        #endif
    }

    @MainActor
    private func updateWidgetData() {
        let context = modelContainer.mainContext
        let books = (try? context.fetch(FetchDescriptor<Book>())) ?? []
        let logs = (try? context.fetch(FetchDescriptor<ReadingLog>())) ?? []
        WidgetDataUpdater.update(books: books, allLogs: logs)

        #if os(iOS) || os(macOS)
        SpotlightManager.reindexAll(books: books)
        #endif
    }
}
