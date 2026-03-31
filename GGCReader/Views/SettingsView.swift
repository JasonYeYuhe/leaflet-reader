import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            #if os(iOS)
            appIconSection
            #endif
            aboutSection
        }
        .navigationTitle("Settings")
    }

    // MARK: - App Icon

    #if os(iOS)
    private var currentIconName: String? {
        UIApplication.shared.alternateIconName
    }

    private var appIconSection: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(AppIconOption.allCases) { option in
                    appIconItem(option)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("App Icon")
        }
    }

    private func appIconItem(_ option: AppIconOption) -> some View {
        let isSelected = currentIconName == option.iconName
        return VStack(spacing: 6) {
            Image(uiImage: option.preview)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .shadow(radius: isSelected ? 4 : 1)

            Text(option.displayName)
                .font(.caption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            setIcon(option)
        }
    }

    private func setIcon(_ option: AppIconOption) {
        HapticManager.selection()
        UIApplication.shared.setAlternateIconName(option.iconName) { error in
            if error != nil {
                HapticManager.notification(.error)
            }
        }
    }
    #endif

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - App Icon Options

#if os(iOS)
enum AppIconOption: String, CaseIterable, Identifiable {
    case blue = "AppIcon"
    case green = "AppIconGreen"
    case purple = "AppIconPurple"
    case orange = "AppIconOrange"
    case teal = "AppIconTeal"
    case dark = "AppIconDark"

    var id: String { rawValue }

    /// nil means default icon
    var iconName: String? {
        self == .blue ? nil : rawValue
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .blue: "Blue"
        case .green: "Green"
        case .purple: "Purple"
        case .orange: "Orange"
        case .teal: "Teal"
        case .dark: "Dark"
        }
    }

    var preview: UIImage {
        // Try to load from asset catalog
        if let img = UIImage(named: rawValue) {
            return img
        }
        // Fallback: solid color
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let color: UIColor = switch self {
            case .blue: .systemBlue
            case .green: .systemGreen
            case .purple: .systemPurple
            case .orange: .systemOrange
            case .teal: .systemTeal
            case .dark: .darkGray
            }
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 24).fill()
        }
    }
}
#endif
