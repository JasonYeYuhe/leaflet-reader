import SwiftUI
import SwiftData
@preconcurrency import AVFoundation

#if os(iOS)
struct ISBNScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allBooks: [Book]

    @State private var scannedISBN: String?
    @State private var lookupResult: BookLookupResult?
    @State private var isLooking = false
    @State private var errorMessage: String?
    @State private var manualISBN = ""
    @State private var showingManualEntry = false

    // Editable fields from lookup
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var genre = ""
    @State private var coverImageData: Data?
    @State private var selectedColor: CoverColor = .blue

    var body: some View {
        NavigationStack {
            ZStack {
                if scannedISBN == nil && !showingManualEntry {
                    scannerView
                } else {
                    resultForm
                }
            }
            .navigationTitle("Scan ISBN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Scanner

    private var scannerView: some View {
        ZStack {
            BarcodeScannerRepresentable { isbn in
                scannedISBN = isbn
                Task { await lookupBook(isbn: isbn) }
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                    Text("Point camera at ISBN barcode")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Usually found on the back cover")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))

                    Button {
                        showingManualEntry = true
                    } label: {
                        Label("Enter ISBN manually", systemImage: "keyboard")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
    }

    // MARK: - Result Form

    private var resultForm: some View {
        Form {
            if showingManualEntry && scannedISBN == nil {
                Section("Enter ISBN") {
                    HStack {
                        TextField("ISBN (10 or 13 digits)", text: $manualISBN)
                            .keyboardType(.numberPad)
                        Button("Look Up") {
                            let isbn = manualISBN.trimmingCharacters(in: .whitespaces)
                            guard !isbn.isEmpty else { return }
                            scannedISBN = isbn
                            Task { await lookupBook(isbn: isbn) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manualISBN.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            if isLooking {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Looking up book...")
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            } else if let error = errorMessage {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    Button("Try Again") {
                        scannedISBN = nil
                        errorMessage = nil
                        showingManualEntry = false
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if !title.isEmpty || errorMessage != nil {
                Section("Book Info") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Total Pages", text: $totalPages)
                        .keyboardType(.numberPad)
                    TextField("Genre", text: $genre)
                }

                if let data = coverImageData, let uiImage = UIImage(data: data) {
                    Section("Cover") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(maxWidth: .infinity)

                        Button(role: .destructive) {
                            coverImageData = nil
                        } label: {
                            Label("Remove Cover", systemImage: "trash")
                        }
                    }
                }

                if coverImageData == nil {
                    Section("Cover Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                            ForEach(CoverColor.allCases, id: \.self) { color in
                                Circle()
                                    .fill(color.color.gradient)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        addBook()
                    } label: {
                        Label("Add Book", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Scan Another") {
                        resetState()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Actions

    private func lookupBook(isbn: String) async {
        isLooking = true
        errorMessage = nil

        do {
            let result = try await BookLookupService.shared.lookup(isbn: isbn)
            lookupResult = result
            title = result.title
            author = result.author
            totalPages = result.totalPages > 0 ? String(result.totalPages) : ""

            // Download cover image
            if let coverURL = result.coverURL {
                if let data = await BookLookupService.shared.downloadCover(from: coverURL) {
                    coverImageData = data
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLooking = false
    }

    private func addBook() {
        let store = StoreManager.shared
        guard store.isPro || allBooks.count < StoreManager.freeBookLimit else {
            dismiss()
            return
        }

        let pages = Int(totalPages) ?? 0
        let book = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            totalPages: pages,
            coverColor: selectedColor
        )
        book.isbn = scannedISBN ?? manualISBN
        book.genre = genre.trimmingCharacters(in: .whitespaces)
        if let result = lookupResult {
            book.publisher = result.publisher
        }
        book.coverImageData = coverImageData
        modelContext.insert(book)
        dismiss()
    }

    private func resetState() {
        scannedISBN = nil
        lookupResult = nil
        isLooking = false
        errorMessage = nil
        manualISBN = ""
        showingManualEntry = false
        title = ""
        author = ""
        totalPages = ""
        genre = ""
        coverImageData = nil
        selectedColor = .blue
    }
}

// MARK: - Barcode Scanner

struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onBarcodeScanned = onBarcodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

@MainActor
class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean13, .ean8, .upce]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)

        captureSession = session
        previewLayer = preview

        let capturedSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            capturedSession.startRunning()
        }
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let isbn = object.stringValue else { return }

        Task { @MainActor in
            guard !hasScanned else { return }
            hasScanned = true
            captureSession?.stopRunning()

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            onBarcodeScanned?(isbn)
        }
    }
}
#endif
