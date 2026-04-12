import SwiftUI
import SwiftData

struct ReadingTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    @State private var activeSession: ReadingSession?
    @State private var elapsedSeconds: Int = 0
    @State private var timerRunning = false
    @State private var endPageInput = ""

    var body: some View {
        VStack(spacing: 20) {
            // Timer display
            ZStack {
                Circle()
                    .stroke(book.coverColor.color.opacity(0.15), lineWidth: 8)
                    .frame(width: 180, height: 180)

                if activeSession != nil {
                    Circle()
                        .trim(from: 0, to: min(Double(elapsedSeconds) / 3600.0, 1.0))
                        .stroke(book.coverColor.color.gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: elapsedSeconds)
                }

                VStack(spacing: 4) {
                    Text(formatTime(elapsedSeconds))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .contentTransition(.numericText())

                    if activeSession != nil {
                        Text("Reading...")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Ready")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Info
            Text(book.title)
                .font(.headline)
                .lineLimit(1)
            Text("Starting at page \(book.currentPage)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Controls
            if activeSession == nil {
                Button {
                    startSession()
                } label: {
                    Label("Start Reading", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(book.coverColor.color)
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("Ended at page:")
                            .font(.subheadline)
                        TextField("Page", text: $endPageInput)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            #endif
                            .frame(width: 80)
                    }

                    let enteredPage = Int(endPageInput) ?? book.currentPage
                    if !endPageInput.isEmpty && enteredPage <= book.currentPage {
                        Text("Page must be greater than \(book.currentPage)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        stopSession()
                    } label: {
                        Label("Stop Reading", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!endPageInput.isEmpty && enteredPage <= book.currentPage)
                }
            }

            // Recent sessions
            let recent = book.sessions.sorted { $0.startTime > $1.startTime }.prefix(5)
            if !recent.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.headline)
                    ForEach(Array(recent)) { session in
                        HStack {
                            Text(session.startTime.formatted(.dateTime.month().day().hour().minute()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if session.endPage > session.startPage {
                                Text("p.\(session.startPage)-\(session.endPage)")
                                    .font(.caption)
                            }
                            Text(session.formattedDuration)
                                .font(.caption.bold())
                                .foregroundStyle(book.coverColor.color)
                        }
                    }
                }
            }
        }
        .padding()
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timerRunning {
                elapsedSeconds += 1
                // Update Live Activity every 30 seconds to save battery
                #if os(iOS)
                if elapsedSeconds % 30 == 0 {
                    LiveActivityManager.shared.updateActivity(
                        elapsedSeconds: elapsedSeconds,
                        currentPage: book.currentPage,
                        startPage: activeSession?.startPage ?? book.currentPage
                    )
                }
                #endif
            }
        }
    }

    private func startSession() {
        let session = ReadingSession(startPage: book.currentPage)
        session.book = book
        modelContext.insert(session)
        activeSession = session
        elapsedSeconds = 0
        endPageInput = ""
        timerRunning = true

        #if os(iOS)
        LiveActivityManager.shared.startActivity(book: book)
        #endif
    }

    private func stopSession() {
        timerRunning = false

        let endPage = Int(endPageInput) ?? book.currentPage
        let finalEndPage = min(max(endPage, book.currentPage), book.totalPages)

        activeSession?.stop(endPage: finalEndPage)

        if finalEndPage > book.currentPage {
            let log = ReadingLog(fromPage: book.currentPage, toPage: finalEndPage)
            log.book = book
            modelContext.insert(log)
            book.currentPage = finalEndPage
            book.lastReadDate = Date()
        }

        #if os(iOS)
        LiveActivityManager.shared.endActivity(
            currentPage: finalEndPage,
            startPage: activeSession?.startPage ?? book.currentPage,
            elapsedSeconds: elapsedSeconds
        )
        #endif

        activeSession = nil

        if book.isFinished {
            book.dateFinished = Date()
            HapticManager.bookFinished()
            ReviewManager.recordBookFinished()
        } else {
            HapticManager.tap()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
