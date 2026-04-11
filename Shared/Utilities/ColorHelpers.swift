import SwiftUI

func colorFor(_ name: String) -> Color {
    switch name {
    case "red": .red
    case "orange": .orange
    case "yellow": .yellow
    case "green": .green
    case "mint": .mint
    case "teal": .teal
    case "cyan": .cyan
    case "blue": .blue
    case "indigo": .indigo
    case "purple": .purple
    case "pink": .pink
    case "brown": .brown
    default: .blue
    }
}
