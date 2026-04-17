import SwiftUI
import SwiftData

@main
struct GGCReaderApp: App {
    let modelContainer: ModelContainer?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            modelContainer = try SharedModelContainer.create()
        } catch {
            print("[GGCReader] Failed to create ModelContainer: \(error)")
            modelContainer = nil
        }
        // Start StoreKit transaction listener early
        _ = StoreManager.shared
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                RootView()
                    .onAppear { updateWidgetData() }
                    .modelContainer(container)
            } else {
                ContentUnavailableView(
                    "Unable to Load Data",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app or check your iCloud settings.")
                )
            }
        }
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
            if let container = modelContainer {
                SettingsView()
                    .modelContainer(container)
            }
        }
        #endif
    }

    @MainActor
    private func updateWidgetData() {
        guard let context = modelContainer?.mainContext else { return }
        let books = (try? context.fetch(FetchDescriptor<Book>())) ?? []
        let logs = (try? context.fetch(FetchDescriptor<ReadingLog>())) ?? []
        WidgetDataUpdater.update(books: books, allLogs: logs)

        #if os(iOS) || os(macOS)
        // Only full reindex once per version; incremental updates happen on save
        let indexedVersion = UserDefaults.standard.string(forKey: "spotlightIndexedVersion") ?? ""
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        if indexedVersion != currentVersion {
            SpotlightManager.reindexAll(books: books)
            UserDefaults.standard.set(currentVersion, forKey: "spotlightIndexedVersion")
        }
        #endif
    }
}
