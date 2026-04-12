import SwiftUI
import SwiftData

#if os(macOS)
enum SidebarItem: String, CaseIterable, Identifiable {
    case books = "Books"
    case goals = "Goals"
    case stats = "Stats"
    case quotes = "Quotes"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .books: "books.vertical"
        case .goals: "flame"
        case .stats: "chart.bar"
        case .quotes: "text.quote"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedSidebarItem: SidebarItem? = .books
    @State private var selectedBook: Book?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedSidebarItem) {
                Section {
                    ForEach(SidebarItem.allCases) { item in
                        Label(LocalizedStringKey(item.rawValue), systemImage: item.icon)
                            .tag(item)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
            .navigationTitle("æstel")
        } content: {
            if selectedSidebarItem == .books {
                BookListView(selectedBook: $selectedBook)
            }
        } detail: {
            switch selectedSidebarItem {
            case .books:
                if let selectedBook {
                    BookDetailView(book: selectedBook)
                } else {
                    ContentUnavailableView {
                        Label("Select a Book", systemImage: "book")
                    } description: {
                        Text("Choose a book from the sidebar to view its details")
                    }
                }
            case .goals:
                NavigationStack {
                    GoalsView()
                }
            case .stats:
                NavigationStack {
                    StatsView()
                }
            case .quotes:
                NavigationStack {
                    QuotesCollectionView()
                }
            case .settings:
                NavigationStack {
                    SettingsView()
                }
            case nil:
                ContentUnavailableView {
                    Label("æstel", systemImage: "book")
                }
            }
        }
        .onChange(of: selectedSidebarItem) { _, newValue in
            withAnimation {
                columnVisibility = newValue == .books ? .all : .detailOnly
            }
        }
    }
}

#else
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BooksTab()
                .tabItem {
                    Label("Books", systemImage: "books.vertical")
                }
                .tag(0)

            NavigationStack {
                GoalsView()
            }
            .tabItem {
                Label("Goals", systemImage: "flame")
            }
            .tag(1)

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
        }
    }
}
#endif

struct BooksTab: View {
    @State private var selectedBook: Book?

    var body: some View {
        NavigationSplitView {
            BookListView(selectedBook: $selectedBook)
        } detail: {
            if let selectedBook {
                BookDetailView(book: selectedBook)
            } else {
                ContentUnavailableView {
                    Label("Select a Book", systemImage: "book")
                } description: {
                    Text("Choose a book from the sidebar to view its details")
                }
            }
        }
    }
}
