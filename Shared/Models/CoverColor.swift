import SwiftUI

enum CoverColor: String, CaseIterable, Codable, Sendable {
    // Original colors
    case red, blue, green, orange, yellow, purple, brown, teal, indigo, pink, mint
    // Expanded palette
    case coral, crimson, navy, sky, forest, lime, gold, amber, violet, lavender
    case slate, charcoal, peach, rose, cyan

    var color: Color {
        switch self {
        case .red: .red
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .yellow: .yellow
        case .purple: .purple
        case .brown: .brown
        case .teal: .teal
        case .indigo: .indigo
        case .pink: .pink
        case .mint: .mint
        case .coral: Color(red: 1.0, green: 0.5, blue: 0.31)
        case .crimson: Color(red: 0.86, green: 0.08, blue: 0.24)
        case .navy: Color(red: 0.0, green: 0.13, blue: 0.4)
        case .sky: Color(red: 0.53, green: 0.81, blue: 0.92)
        case .forest: Color(red: 0.13, green: 0.55, blue: 0.13)
        case .lime: Color(red: 0.6, green: 0.8, blue: 0.2)
        case .gold: Color(red: 1.0, green: 0.84, blue: 0.0)
        case .amber: Color(red: 1.0, green: 0.75, blue: 0.0)
        case .violet: Color(red: 0.56, green: 0.0, blue: 1.0)
        case .lavender: Color(red: 0.71, green: 0.49, blue: 0.86)
        case .slate: Color(red: 0.44, green: 0.5, blue: 0.56)
        case .charcoal: Color(red: 0.21, green: 0.27, blue: 0.31)
        case .peach: Color(red: 1.0, green: 0.8, blue: 0.64)
        case .rose: Color(red: 1.0, green: 0.41, blue: 0.71)
        case .cyan: .cyan
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
