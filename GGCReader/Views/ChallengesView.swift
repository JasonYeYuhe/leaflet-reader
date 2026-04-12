import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReadingChallenge.endDate) private var challenges: [ReadingChallenge]
    @Query(sort: \ReadingLog.date, order: .reverse) private var allLogs: [ReadingLog]
    @Query private var allBooks: [Book]
    var storeManager = StoreManager.shared

    @State private var showingAddChallenge = false
    @State private var showingPaywall = false

    private var activeChallenges: [ReadingChallenge] {
        challenges.filter(\.isActive)
    }

    private var completedChallenges: [ReadingChallenge] {
        challenges.filter(\.isCompleted)
    }

    private var expiredChallenges: [ReadingChallenge] {
        challenges.filter(\.isExpired)
    }

    private var canAddChallenge: Bool {
        storeManager.isPro || activeChallenges.count < 1
    }

    var body: some View {
        List {
            if !activeChallenges.isEmpty {
                Section("Active") {
                    ForEach(activeChallenges) { challenge in
                        challengeRow(challenge)
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            modelContext.delete(activeChallenges[i])
                        }
                    }
                }
            }

            if !completedChallenges.isEmpty {
                Section("Completed") {
                    ForEach(completedChallenges) { challenge in
                        challengeRow(challenge)
                    }
                }
            }

            if !expiredChallenges.isEmpty {
                Section("Expired") {
                    ForEach(expiredChallenges) { challenge in
                        challengeRow(challenge)
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            modelContext.delete(expiredChallenges[i])
                        }
                    }
                }
            }

            if challenges.isEmpty {
                ContentUnavailableView {
                    Label("No Challenges", systemImage: "flag.checkered")
                } description: {
                    Text("Create a reading challenge to stay motivated")
                }
            }
        }
        .navigationTitle("Challenges")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if canAddChallenge {
                        showingAddChallenge = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddChallenge) {
            AddChallengeView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear { checkCompletions() }
    }

    // MARK: - Challenge Row

    private func challengeRow(_ challenge: ReadingChallenge) -> some View {
        let progress = currentProgress(for: challenge)
        let percentage = min(Double(progress) / max(Double(challenge.targetValue), 1), 1.0)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: challenge.challengeType.icon)
                    .foregroundStyle(challenge.color.color)
                Text(challenge.title)
                    .font(.subheadline.bold())
                Spacer()
                if challenge.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if challenge.isExpired {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    Text("\(challenge.daysRemaining)d left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.fill.tertiary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(challenge.isCompleted ? .green : challenge.color.color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(progress) / \(challenge.targetValue) \(challenge.challengeType.unitName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(challenge.isCompleted ? .green : challenge.color.color)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Progress Calculation

    private func currentProgress(for challenge: ReadingChallenge) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: challenge.startDate)
        let end = cal.startOfDay(for: min(challenge.endDate, Date()))

        switch challenge.challengeType {
        case .booksCount:
            return allBooks.filter {
                $0.isFinished &&
                ($0.dateFinished ?? $0.lastReadDate ?? .distantFuture) >= start &&
                ($0.dateFinished ?? $0.lastReadDate ?? .distantFuture) <= end
            }.count

        case .pagesCount:
            return allLogs.filter { $0.date >= start && $0.date <= end }
                .reduce(0) { $0 + $1.pagesRead }

        case .streakDays:
            var daySet = Set<Date>()
            for log in allLogs where log.date >= start && log.date <= end {
                daySet.insert(cal.startOfDay(for: log.date))
            }
            var best = 0
            var current = 0
            let totalDays = max((cal.dateComponents([.day], from: start, to: end).day ?? 0) + 1, 1)
            for offset in 0..<totalDays {
                guard let date = cal.date(byAdding: .day, value: offset, to: start) else { continue }
                if daySet.contains(date) {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
                }
            }
            return best

        case .readingDays:
            var daySet = Set<Date>()
            for log in allLogs where log.date >= start && log.date <= end {
                daySet.insert(cal.startOfDay(for: log.date))
            }
            return daySet.count
        }
    }

    private func checkCompletions() {
        for challenge in activeChallenges {
            let progress = currentProgress(for: challenge)
            if progress >= challenge.targetValue {
                challenge.isCompleted = true
                challenge.dateCompleted = Date()
                HapticManager.goalAchieved()
            }
        }
    }
}

// MARK: - Add Challenge

struct AddChallengeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedType: ChallengeType = .booksCount
    @State private var targetValue = ""
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedColor: CoverColor = .blue

    private static let presets: [(String, ChallengeType, Int, Int)] = [
        ("52 Books in a Year", .booksCount, 52, 365),
        ("30-Day Reading Streak", .streakDays, 30, 30),
        ("Read 5000 Pages", .pagesCount, 5000, 90),
        ("Read Every Day This Month", .readingDays, 30, 30),
    ]

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (Int(targetValue) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Presets") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Self.presets, id: \.0) { preset in
                                Button {
                                    title = preset.0
                                    selectedType = preset.1
                                    targetValue = String(preset.2)
                                    endDate = Calendar.current.date(byAdding: .day, value: preset.3, to: Date()) ?? Date()
                                } label: {
                                    Text(preset.0)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(title == preset.0 ? Color.accentColor : Color.accentColor.opacity(0.1), in: Capsule())
                                        .foregroundStyle(title == preset.0 ? .white : .accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Challenge Details") {
                    TextField("Challenge Name", text: $title)
                    Picker("Type", selection: $selectedType) {
                        ForEach(ChallengeType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    TextField("Target (\(selectedType.unitName))", text: $targetValue)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    DatePicker("End Date", selection: $endDate, in: Date()..., displayedComponents: .date)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach([CoverColor.blue, .green, .orange, .purple, .red, .teal, .indigo, .pink], id: \.self) { color in
                            Circle()
                                .fill(color.color.gradient)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }
            }
            .navigationTitle("New Challenge")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createChallenge() }
                        .disabled(!isValid)
                        .bold()
                }
            }
        }
    }

    private func createChallenge() {
        let challenge = ReadingChallenge(
            title: title.trimmingCharacters(in: .whitespaces),
            type: selectedType,
            target: Int(targetValue) ?? 0,
            endDate: endDate,
            color: selectedColor
        )
        modelContext.insert(challenge)
        HapticManager.tap()
        dismiss()
    }
}
