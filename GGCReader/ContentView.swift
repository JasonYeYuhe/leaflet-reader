import SwiftUI
import SwiftData

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
