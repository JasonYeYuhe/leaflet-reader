import SwiftData
import Foundation

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var colorName: String = "blue"
    var books: [Book] = []

    var color: CoverColor {
        get { CoverColor(rawValue: colorName) ?? .blue }
        set { colorName = newValue.rawValue }
    }

    init(name: String, color: CoverColor = .blue) {
        self.id = UUID()
        self.name = name
        self.colorName = color.rawValue
    }
}
