import SwiftUI

struct BookCoverView: View {
    let title: String
    let color: CoverColor
    var size: CGFloat = 60
    var imageData: Data? = nil

    private var initials: String {
        let words = title.prefix(2)
        return String(words.prefix(2))
    }

    var body: some View {
        Group {
            if let imageData, let uiImage = platformImage(from: imageData) {
                Image(decorative: uiImage, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size * 1.4)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
                    .shadow(radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(color.color.gradient)
                    .frame(width: size, height: size * 1.4)
                    .overlay {
                        Text(initials)
                            .font(.system(size: size * 0.3, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                    }
                    .shadow(color: color.color.opacity(0.3), radius: 4, y: 2)
            }
        }
    }

    private func platformImage(from data: Data) -> CGImage? {
        #if os(iOS) || os(watchOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return uiImage.cgImage
        #elseif os(macOS)
        guard let nsImage = NSImage(data: data),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return cgImage
        #endif
    }
}

#Preview {
    HStack(spacing: 20) {
        BookCoverView(title: "Swift Programming", color: .blue)
        BookCoverView(title: "Design Patterns", color: .red, size: 80)
        BookCoverView(title: "Clean Code", color: .green, size: 40)
    }
    .padding()
}
