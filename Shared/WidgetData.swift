import Foundation

struct WidgetBookData: Codable {
    let title: String
    let author: String
    let currentPage: Int
    let totalPages: Int
    let colorName: String
    let progressPercentage: Double
}

struct WidgetData: Codable {
    let currentBook: WidgetBookData?
    let todayPages: Int
    let dailyGoal: Int
    let currentStreak: Int
    let lastUpdated: Date

    static let appGroupID = "group.com.jason.ggcreader"

    static func save(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "widgetData")
        }
    }

    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "widgetData"),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }

    static var placeholder: WidgetData {
        WidgetData(
            currentBook: WidgetBookData(
                title: "The Great Gatsby",
                author: "F. Scott Fitzgerald",
                currentPage: 85,
                totalPages: 180,
                colorName: "blue",
                progressPercentage: 0.47
            ),
            todayPages: 15,
            dailyGoal: 20,
            currentStreak: 7,
            lastUpdated: Date()
        )
    }
}
