import SwiftUI

// MARK: - Share Card Sheet

enum CardTheme: String, CaseIterable, Identifiable {
    case standard, dark, minimal, gradient

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .dark: "Dark"
        case .minimal: "Minimal"
        case .gradient: "Gradient"
        }
    }
}

struct ShareCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    @State private var renderedImage: Image?
    @State private var renderedUIImage: PlatformShareImage?
    @State private var selectedTheme: CardTheme = .standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ShareCardContent(book: book, theme: selectedTheme)
                    .frame(width: 340, height: 480)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Theme picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(CardTheme.allCases) { theme in
                            Button {
                                selectedTheme = theme
                                renderCard()
                            } label: {
                                Text(theme.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTheme == theme ? Color.accentColor : Color.accentColor.opacity(0.1), in: Capsule())
                                    .foregroundStyle(selectedTheme == theme ? .white : .accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                if let renderedUIImage {
                    ShareLink(
                        item: renderedUIImage,
                        preview: SharePreview(book.title, image: renderedImage ?? Image(systemName: "book"))
                    ) {
                        Label("Share Card", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Share")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { renderCard() }
        }
        .presentationDetents([.large])
    }

    @MainActor
    private func renderCard() {
        let cardView = ShareCardContent(book: book, theme: selectedTheme)
            .frame(width: 340, height: 480)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3

        #if os(iOS)
        if let uiImage = renderer.uiImage {
            renderedUIImage = PlatformShareImage(image: uiImage)
            renderedImage = Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = renderer.nsImage {
            renderedUIImage = PlatformShareImage(image: nsImage)
            renderedImage = Image(nsImage: nsImage)
        }
        #endif
    }
}

// MARK: - Card Content

struct ShareCardContent: View {
    let book: Book
    var theme: CardTheme = .standard

    private var readingDays: Int {
        guard let lastRead = book.lastReadDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: book.dateAdded, to: lastRead).day ?? 0
        return max(days, 1)
    }

    private var totalPagesRead: Int {
        book.readingLogs.reduce(0) { $0 + $1.pagesRead }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top area with cover
            ZStack {
                switch theme {
                case .standard:
                    LinearGradient(colors: [book.coverColor.color, book.coverColor.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .dark:
                    LinearGradient(colors: [Color(white: 0.15), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .minimal:
                    Color.white
                case .gradient:
                    LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                }

                VStack(spacing: 12) {
                    BookCoverView(title: book.title, color: book.coverColor, size: 70, imageData: book.coverImageData)

                    Text(book.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(theme == .minimal ? Color.primary : Color.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 20)

                    Text(book.author)
                        .font(.system(size: 13))
                        .foregroundStyle(theme == .minimal ? Color.secondary : Color.white.opacity(0.85))
                }
                .padding(.vertical, 20)
            }
            .frame(height: 260)

            // Bottom white area with stats
            VStack(spacing: 16) {
                // Stars
                if let rating = book.rating {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundStyle(star <= rating ? .yellow : .secondary.opacity(0.3))
                        }
                    }
                }

                // Review
                if let review = book.review, !review.isEmpty {
                    Text("\"\(review)\"")
                        .font(.system(size: 12, design: .serif))
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 20)
                }

                // Stats row
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text(book.bookType == .audiobook ? book.formattedProgress : "\(book.totalPages)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(book.bookType.unitName)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    if readingDays > 0 {
                        VStack(spacing: 2) {
                            Text("\(readingDays)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("days")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !book.genre.isEmpty {
                        VStack(spacing: 2) {
                            Text(book.genre)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            Text("genre")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Branding
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10))
                    Text("æstel")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 12)
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
            .background(theme == .dark ? Color(white: 0.12) : .white)
            .foregroundStyle(theme == .dark ? .white : .primary)
        }
    }
}

// MARK: - Platform Image for ShareLink

#if os(iOS)
struct PlatformShareImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = item.image.pngData() else {
                throw ShareError.renderFailed
            }
            return data
        }
    }
}
#elseif os(macOS)
struct PlatformShareImage: Transferable {
    let image: NSImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let tiff = item.image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let data = rep.representation(using: .png, properties: [:]) else {
                throw ShareError.renderFailed
            }
            return data
        }
    }
}
#endif

enum ShareError: Error {
    case renderFailed
}
