import SwiftUI

struct QuoteShareCardView: View {
    let note: BookNote

    var body: some View {
        VStack(spacing: 0) {
            // Quote area
            VStack(spacing: 16) {
                Image(systemName: "text.quote")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))

                Text("\"\(note.content)\"")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(8)
                    .padding(.horizontal, 24)

                if note.page > 0 {
                    Text("— p.\(note.page)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        (note.book?.coverColor.color ?? .blue),
                        (note.book?.coverColor.color ?? .blue).opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Book info area
            HStack(spacing: 12) {
                if let book = note.book {
                    BookCoverView(title: book.title, color: book.coverColor, size: 36, imageData: book.coverImageData)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text(book.author)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 9))
                    Text("æstel")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(12)
            .background(.white)
        }
        .frame(width: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 4)
    }
}

// MARK: - Quote Share Sheet

struct QuoteShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let note: BookNote
    @State private var renderedImage: Image?
    @State private var shareImage: PlatformShareImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                QuoteShareCardView(note: note)

                if let shareImage {
                    ShareLink(
                        item: shareImage,
                        preview: SharePreview("Quote from \(note.book?.title ?? "Book")", image: renderedImage ?? Image(systemName: "text.quote"))
                    ) {
                        Label("Share Quote", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Share Quote")
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
        .presentationDetents([.medium, .large])
    }

    @MainActor
    private func renderCard() {
        let renderer = ImageRenderer(content: QuoteShareCardView(note: note))
        renderer.scale = 3

        #if os(iOS)
        if let uiImage = renderer.uiImage {
            shareImage = PlatformShareImage(image: uiImage)
            renderedImage = Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = renderer.nsImage {
            shareImage = PlatformShareImage(image: nsImage)
            renderedImage = Image(nsImage: nsImage)
        }
        #endif
    }
}
