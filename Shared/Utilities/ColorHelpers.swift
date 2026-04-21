import SwiftUI

func colorFor(_ name: String) -> Color {
    CoverColor(rawValue: name)?.color ?? .blue
}
