import SwiftUI
import SwiftData

struct RatingPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book
    @State private var selectedRating: Int = 0
    @State private var reviewText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Book cover
                BookCoverView(title: book.title, color: book.coverColor, size: 80, imageData: book.coverImageData)

                VStack(spacing: 4) {
                    Text(book.title)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("How was this book?")
                    .font(.headline)

                // Star rating
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                            .font(.largeTitle)
                            .foregroundStyle(star <= selectedRating ? .yellow : .secondary.opacity(0.3))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedRating = star
                                }
                                HapticManager.selection()
                            }
                    }
                }

                // Review text
                VStack(alignment: .leading, spacing: 6) {
                    Text("Review (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $reviewText)
                        .frame(minHeight: 80, maxHeight: 150)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Rate Book")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRating()
                    }
                    .disabled(selectedRating == 0 && reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .bold()
                }
            }
            .onAppear {
                selectedRating = book.rating ?? 0
                reviewText = book.review ?? ""
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveRating() {
        book.rating = selectedRating > 0 ? selectedRating : nil
        let trimmed = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        book.review = trimmed.isEmpty ? nil : trimmed
        HapticManager.notification(.success)
        dismiss()
    }
}
