import SwiftUI
import VisionKit

#if os(iOS)
struct BookScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var recognizedTexts: [String] = []
    @State private var showingResults = false
    @State private var selectedTitle = ""
    @State private var selectedAuthor = ""
    @State private var isScanning = true

    var body: some View {
        NavigationStack {
            ZStack {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    if isScanning {
                        DataScannerRepresentable(recognizedTexts: $recognizedTexts, onScanComplete: {
                            isScanning = false
                            showingResults = true
                        })
                        .ignoresSafeArea()

                        VStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Text("Point camera at book cover")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Tap the shutter button when ready")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                Button {
                                    isScanning = false
                                    showingResults = true
                                } label: {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 64))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 4)
                                }
                                .padding(.top, 8)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding()
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Camera Not Available", systemImage: "camera.slash")
                    } description: {
                        Text("This device does not support text scanning. Please enter book details manually.")
                    }
                }
            }
            .navigationTitle("Scan Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingResults) {
                ScanResultsView(
                    recognizedTexts: recognizedTexts,
                    selectedTitle: $selectedTitle,
                    selectedAuthor: $selectedAuthor,
                    onConfirm: { title, author in
                        let book = Book(title: title, author: author, totalPages: 0)
                        modelContext.insert(book)
                        dismiss()
                    },
                    onRescan: {
                        recognizedTexts = []
                        isScanning = true
                        showingResults = false
                    }
                )
            }
        }
    }
}

struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var recognizedTexts: [String]
    var onScanComplete: () -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: DataScannerRepresentable

        init(_ parent: DataScannerRepresentable) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            var texts: [String] = []
            for item in allItems {
                if case .text(let text) = item {
                    texts.append(text.transcript)
                }
            }
            parent.recognizedTexts = texts
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            var texts: [String] = []
            for item in allItems {
                if case .text(let text) = item {
                    texts.append(text.transcript)
                }
            }
            parent.recognizedTexts = texts
        }
    }
}

struct ScanResultsView: View {
    let recognizedTexts: [String]
    @Binding var selectedTitle: String
    @Binding var selectedAuthor: String
    var onConfirm: (String, String) -> Void
    var onRescan: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Recognized Text") {
                    if recognizedTexts.isEmpty {
                        Text("No text detected. Try scanning again.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(recognizedTexts.enumerated()), id: \.offset) { index, text in
                            HStack {
                                Text(text)
                                    .font(.subheadline)
                                Spacer()
                                Menu {
                                    Button("Use as Title") {
                                        selectedTitle = text
                                    }
                                    Button("Use as Author") {
                                        selectedAuthor = text
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Book Details") {
                    TextField("Title", text: $selectedTitle)
                        .font(.headline)
                    TextField("Author", text: $selectedAuthor)
                }

                Section {
                    Button("Add Book") {
                        guard !selectedTitle.isEmpty else { return }
                        onConfirm(selectedTitle, selectedAuthor)
                    }
                    .disabled(selectedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)

                    Button("Scan Again") {
                        onRescan()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                autoDetectTitleAndAuthor()
            }
        }
    }

    private func autoDetectTitleAndAuthor() {
        guard !recognizedTexts.isEmpty else { return }
        // Heuristic: longest text is likely the title, second longest is author
        let sorted = recognizedTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }

        if let first = sorted.first, selectedTitle.isEmpty {
            selectedTitle = first
        }
        if sorted.count > 1, selectedAuthor.isEmpty {
            selectedAuthor = sorted[1]
        }
    }
}
#endif
