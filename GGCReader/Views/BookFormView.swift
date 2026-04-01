import SwiftUI
import SwiftData
import PhotosUI

struct BookFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allBooks: [Book]

    var bookToEdit: Book?

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var selectedColor: CoverColor = .blue
    @State private var coverImageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false

    private var isEditing: Bool { bookToEdit != nil }
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(totalPages) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Book Info") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Total Pages", text: $totalPages)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                // Cover image
                Section {
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        #if os(iOS)
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        #endif
                    }
                    .listRowSeparator(.hidden)

                    if coverImageData != nil {
                        Button(role: .destructive) {
                            coverImageData = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Cover Photo")
                } footer: {
                    if coverImageData == nil {
                        Text("Or choose a color below")
                    }
                }

                // Color picker
                Section("Cover Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(CoverColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(color.color.gradient)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == color && coverImageData == nil {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                    HapticManager.selection()
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Preview
                Section {
                    BookCoverView(
                        title: title.isEmpty ? "Preview" : title,
                        color: selectedColor,
                        size: 80,
                        imageData: coverImageData
                    )
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(isEditing ? "Edit Book" : "Add Book")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveBook()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let book = bookToEdit {
                    title = book.title
                    author = book.author
                    totalPages = String(book.totalPages)
                    selectedColor = book.coverColor
                    coverImageData = book.coverImageData
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        coverImageData = compressImage(data)
                    }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingCamera) {
                CameraCaptureView { image in
                    if let data = image.jpegData(compressionQuality: 0.7) {
                        coverImageData = data
                    }
                }
                .ignoresSafeArea()
            }
            #endif
        }
    }

    private func saveBook() {
        let pages = Int(totalPages) ?? 0
        if let book = bookToEdit {
            book.title = title.trimmingCharacters(in: .whitespaces)
            book.author = author.trimmingCharacters(in: .whitespaces)
            book.totalPages = pages
            book.coverColor = selectedColor
            book.coverImageData = coverImageData
        } else {
            let store = StoreManager.shared
            guard store.isPro || allBooks.count < StoreManager.freeBookLimit else {
                dismiss()
                return
            }
            let book = Book(
                title: title.trimmingCharacters(in: .whitespaces),
                author: author.trimmingCharacters(in: .whitespaces),
                totalPages: pages,
                coverColor: selectedColor
            )
            book.coverImageData = coverImageData
            modelContext.insert(book)
        }
        dismiss()
    }

    private func compressImage(_ data: Data) -> Data {
        #if os(iOS)
        guard let image = UIImage(data: data) else { return data }
        // Resize to max 600px wide for storage efficiency
        let maxWidth: CGFloat = 600
        if image.size.width > maxWidth {
            let scale = maxWidth / image.size.width
            let newSize = CGSize(width: maxWidth, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            return resized.jpegData(compressionQuality: 0.7) ?? data
        }
        return image.jpegData(compressionQuality: 0.7) ?? data
        #else
        return data
        #endif
    }
}

// MARK: - Camera Capture

#if os(iOS)
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
#endif
