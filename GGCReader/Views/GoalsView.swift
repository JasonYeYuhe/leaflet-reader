import SwiftUI
import SwiftData
import EventKit

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReadingLog.date, order: .reverse) private var allLogs: [ReadingLog]
    @Query(sort: \Book.lastReadDate, order: .reverse) private var books: [Book]
    @AppStorage("dailyPageGoal") private var dailyPageGoal: Int = 20
    @State private var calendarManager = CalendarManager()
    @State private var reminderManager = ReminderManager()
    @State private var showingAddTask = false
    @State private var preselectedBook: Book?
    @State private var taskPages: Int = 20
    @State private var taskDate = Date()
    @State private var taskCustomTitle = ""
    @State private var useCustomTitle = false
    @State private var showCelebration = false
    @State private var previousProgress: Double = 0

    private let calendar = Calendar.current

    // MARK: - Computed Data

    private var dailyPages: [Date: Int] {
        var map: [Date: Int] = [:]
        for log in allLogs {
            let day = calendar.startOfDay(for: log.date)
            map[day, default: 0] += log.pagesRead
        }
        return map
    }

    private var todayPages: Int {
        dailyPages[calendar.startOfDay(for: Date())] ?? 0
    }

    private var todayProgress: Double {
        guard dailyPageGoal > 0 else { return 0 }
        return min(Double(todayPages) / Double(dailyPageGoal), 1.0)
    }

    private var currentStreak: Int {
        let pages = dailyPages
        var streak = 0
        var date = calendar.startOfDay(for: Date())

        if (pages[date] ?? 0) < dailyPageGoal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }

        while (pages[date] ?? 0) >= dailyPageGoal {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }

        return streak
    }

    private var bestStreak: Int {
        guard let earliest = allLogs.min(by: { $0.date < $1.date })?.date else { return 0 }
        let pages = dailyPages
        let start = calendar.startOfDay(for: earliest)
        let today = calendar.startOfDay(for: Date())
        guard let totalDays = calendar.dateComponents([.day], from: start, to: today).day else { return 0 }

        var best = 0
        var current = 0
        for offset in 0...totalDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            if (pages[date] ?? 0) >= dailyPageGoal {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    private var heatmapData: [(date: Date, pages: Int)] {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let startDate = calendar.date(byAdding: .day, value: -28, to: thisMonday) else { return [] }

        let totalDays = (calendar.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1

        return (0..<totalDays).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            return (date, pages[date] ?? 0)
        }
    }

    private var readingBooks: [Book] {
        books.filter { !$0.isFinished }
    }

    // MARK: - Weekly Insights

    private var weeklyPages: Int {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reduce(0) { sum, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return sum }
            return sum + (pages[date] ?? 0)
        }
    }

    private var weeklyAverage: Double {
        Double(weeklyPages) / 7.0
    }

    private var mostActiveDay: String? {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())
        let weekDays = (0..<7).compactMap { offset -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date, pages[date] ?? 0)
        }
        guard let best = weekDays.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: best.0)
    }

    private var projectedCompletion: (book: Book, daysLeft: Int)? {
        guard weeklyAverage > 0 else { return nil }
        guard let book = readingBooks.first else { return nil }
        let remaining = book.pagesRemaining
        let days = Int(ceil(Double(remaining) / weeklyAverage))
        return (book, days)
    }

    private var weeklyTrend: Double {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())

        let thisWeek = (0..<7).reduce(0) { sum, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return sum }
            return sum + (pages[date] ?? 0)
        }
        let lastWeek = (7..<14).reduce(0) { sum, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return sum }
            return sum + (pages[date] ?? 0)
        }

        guard lastWeek > 0 else { return thisWeek > 0 ? 1.0 : 0.0 }
        return Double(thisWeek - lastWeek) / Double(lastWeek)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    GoalRingSection(
                        todayPages: todayPages,
                        dailyPageGoal: dailyPageGoal,
                        todayProgress: todayProgress
                    )
                    StreakSection(
                        currentStreak: currentStreak,
                        bestStreak: bestStreak
                    )
                    GoalSettingSection(dailyPageGoal: $dailyPageGoal)
                    WeeklyInsightsSection(
                        weeklyPages: weeklyPages,
                        weeklyAverage: weeklyAverage,
                        mostActiveDay: mostActiveDay,
                        weeklyTrend: weeklyTrend,
                        projectedCompletion: projectedCompletion
                    )
                    HeatmapSection(
                        heatmapData: heatmapData,
                        dailyPageGoal: dailyPageGoal
                    )
                    BadgesCard(
                        allLogs: allLogs,
                        books: books,
                        currentStreak: currentStreak,
                        bestStreak: bestStreak,
                        dailyPageGoal: dailyPageGoal
                    )
                    reminderCard
                    calendarCard
                }
                .padding()
            }
            .navigationTitle("Goals")
            .task {
                await calendarManager.requestAccess()
                await reminderManager.checkAuthStatus()
                previousProgress = todayProgress
            }
            .onChange(of: todayProgress) { oldValue, newValue in
                if oldValue < 1.0 && newValue >= 1.0 {
                    HapticManager.goalAchieved()
                    showCelebration = true
                }
                if newValue >= 1.0 && calendarManager.isSetUp {
                    calendarManager.recordGoalCompletion(pages: todayPages, goal: dailyPageGoal)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                addTaskSheet
            }

            CelebrationView(
                isShowing: $showCelebration,
                emoji: "🎉",
                message: "Goal Complete!"
            )
        }
    }

    // MARK: - Reminder Card

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.orange)
                Text("Reading Reminder")
                    .font(.headline)
                Spacer()
            }

            if !reminderManager.isAuthorized {
                VStack(spacing: 8) {
                    Text("Get a daily nudge to keep your reading habit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await reminderManager.requestAccess() }
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.badge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } else {
                Toggle(isOn: Binding(
                    get: { reminderManager.reminderEnabled },
                    set: { reminderManager.reminderEnabled = $0 }
                )) {
                    Text("Daily Reminder")
                        .font(.subheadline)
                }

                if reminderManager.reminderEnabled {
                    DatePicker(
                        "Remind at",
                        selection: Binding(
                            get: {
                                var comps = DateComponents()
                                comps.hour = reminderManager.reminderHour
                                comps.minute = reminderManager.reminderMinute
                                return Calendar.current.date(from: comps) ?? Date()
                            },
                            set: { date in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                reminderManager.reminderHour = comps.hour ?? 21
                                reminderManager.reminderMinute = comps.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.red)
                Text("Calendar")
                    .font(.headline)
                Spacer()
                if calendarManager.isSetUp {
                    Button {
                        calendarManager.refreshEvents()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        preselectedBook = nil
                        taskPages = dailyPageGoal
                        taskDate = Date()
                        taskCustomTitle = ""
                        useCustomTitle = false
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }

            if !calendarManager.isSetUp {
                VStack(spacing: 8) {
                    Text("Sync reading tasks with Apple Calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await calendarManager.requestAccess() }
                    } label: {
                        Label("Connect Calendar", systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                if !readingBooks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(readingBooks) { book in
                                Button {
                                    preselectedBook = book
                                    taskPages = dailyPageGoal
                                    taskDate = Date()
                                    taskCustomTitle = ""
                                    useCustomTitle = false
                                    showingAddTask = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(book.coverColor.color.gradient)
                                            .frame(width: 10, height: 10)
                                        Text(book.title)
                                            .lineLimit(1)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(book.coverColor.color.opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !calendarManager.todayEvents.isEmpty {
                    Text("Today")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    ForEach(calendarManager.todayEvents, id: \.eventIdentifier) { event in
                        taskRow(event: event)
                    }
                }

                if !calendarManager.upcomingEvents.isEmpty {
                    Text("Upcoming")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    ForEach(calendarManager.upcomingEvents, id: \.eventIdentifier) { event in
                        taskRow(event: event, showDate: true)
                    }
                }

                if calendarManager.todayEvents.isEmpty && calendarManager.upcomingEvents.isEmpty {
                    Text("No reading tasks yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }

                Text("Tasks added here also appear in Apple Calendar")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Task Row

    private func taskRow(event: EKEvent, showDate: Bool = false) -> some View {
        let isCompleted = (event.title ?? "").hasPrefix("✅")
        let displayTitle = isCompleted ? String((event.title ?? "").dropFirst(2)) : (event.title ?? "")
        let meta = TaskMetadata.parse(from: event.notes)
        let linkedBook = meta.flatMap { m in books.first(where: { $0.id == m.bookID }) }

        return HStack(spacing: 10) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCompleted ? .green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.subheadline)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                HStack(spacing: 4) {
                    if let book = linkedBook, let meta {
                        Circle()
                            .fill(book.coverColor.color.gradient)
                            .frame(width: 6, height: 6)
                        Text("\(meta.pages) \(String(localized: "pages"))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if showDate {
                        Text(event.startDate.formatted(.dateTime.month().day().weekday(.abbreviated)))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if !isCompleted {
                        Text("Tap to complete")
                            .font(.caption2)
                            .foregroundStyle(.blue.opacity(0.6))
                    }
                }
            }

            Spacer()

            Button {
                calendarManager.deleteTask(event)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isCompleted ? Color.green.opacity(0.06) : Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture {
            completeTask(event)
        }
    }

    // MARK: - Complete Task

    private func completeTask(_ event: EKEvent) {
        let wasCompleted = calendarManager.isCompleted(event)
        let meta = calendarManager.metadata(for: event)

        HapticManager.taskDone()
        calendarManager.toggleTaskCompletion(event)

        if !wasCompleted, let meta {
            if let book = books.first(where: { $0.id == meta.bookID }) {
                let fromPage = book.currentPage
                let toPage = min(fromPage + meta.pages, book.totalPages)
                if toPage > fromPage {
                    let log = ReadingLog(fromPage: fromPage, toPage: toPage)
                    log.book = book
                    modelContext.insert(log)
                    book.currentPage = toPage
                    book.lastReadDate = Date()
                    do { try modelContext.save() } catch { print("[GoalsView] Failed to save reading log: \(error)") }
                }
            }
        }

        if wasCompleted, let meta {
            if let book = books.first(where: { $0.id == meta.bookID }) {
                let today = Calendar.current.startOfDay(for: Date())
                let matchingLogs = book.readingLogs
                    .filter { Calendar.current.startOfDay(for: $0.date) == today }
                    .sorted { $0.date > $1.date }
                if let lastLog = matchingLogs.first(where: { $0.pagesRead == meta.pages }) {
                    book.currentPage = max(book.currentPage - lastLog.pagesRead, 0)
                    book.lastReadDate = Date()
                    modelContext.delete(lastLog)
                    do { try modelContext.save() } catch { print("[GoalsView] Failed to save undo: \(error)") }
                }
            }
        }
    }

    // MARK: - Add Task Sheet

    private var generatedTitle: String {
        if useCustomTitle && !taskCustomTitle.isEmpty {
            return taskCustomTitle
        }
        if let book = preselectedBook {
            return String(localized: "Read") + " \(taskPages) " + String(localized: "pages") + " - \(book.title)"
        }
        return taskCustomTitle
    }

    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                Section {
                    if readingBooks.isEmpty {
                        Text("No books in progress")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(readingBooks) { book in
                            Button {
                                preselectedBook = book
                                useCustomTitle = false
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(book.coverColor.color.gradient)
                                        .frame(width: 14, height: 14)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(book.title)
                                            .foregroundStyle(.primary)
                                        Text("p.\(book.currentPage)/\(book.totalPages) · \(book.pagesRemaining) left")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if preselectedBook?.id == book.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Book")
                }

                if preselectedBook != nil {
                    Section {
                        HStack {
                            Text("Pages")
                            Spacer()

                            HStack(spacing: 10) {
                                Button {
                                    if taskPages > 5 { taskPages -= 5 }
                                } label: {
                                    Text("-5")
                                        .font(.caption.bold())
                                        .frame(width: 32, height: 32)
                                        .background(.blue.opacity(0.12), in: Circle())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    if taskPages > 1 { taskPages -= 1 }
                                } label: {
                                    Text("-1")
                                        .font(.caption.bold())
                                        .frame(width: 32, height: 32)
                                        .background(.blue.opacity(0.08), in: Circle())
                                }
                                .buttonStyle(.plain)

                                Text("\(taskPages)")
                                    .font(.title3.bold())
                                    .monospacedDigit()
                                    .frame(width: 44)

                                Button {
                                    taskPages += 1
                                } label: {
                                    Text("+1")
                                        .font(.caption.bold())
                                        .frame(width: 32, height: 32)
                                        .background(.blue.opacity(0.08), in: Circle())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    taskPages += 5
                                } label: {
                                    Text("+5")
                                        .font(.caption.bold())
                                        .frame(width: 32, height: 32)
                                        .background(.blue.opacity(0.12), in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .foregroundStyle(.blue)
                        }

                        HStack(spacing: 8) {
                            ForEach([10, 20, 30, 50], id: \.self) { p in
                                Button {
                                    taskPages = p
                                } label: {
                                    Text("\(p)")
                                        .font(.caption.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(taskPages == p ? Color.blue : Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(taskPages == p ? .white : .blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("How Many Pages")
                    }
                }

                Section {
                    DatePicker("Date", selection: $taskDate, displayedComponents: .date)
                }

                Section {
                    if preselectedBook != nil {
                        HStack {
                            Image(systemName: "text.quote")
                                .foregroundStyle(.secondary)
                            Text(generatedTitle)
                                .font(.subheadline)
                        }
                    }

                    Toggle("Custom Title", isOn: $useCustomTitle)

                    if useCustomTitle || preselectedBook == nil {
                        TextField("e.g. Read Chapter 5", text: $taskCustomTitle)
                    }
                } header: {
                    Text("Task Title")
                }
            }
            .navigationTitle("New Reading Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddTask = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let title = generatedTitle
                        guard !title.isEmpty else { return }
                        let meta: TaskMetadata?
                        if let book = preselectedBook {
                            meta = TaskMetadata(bookID: book.id, pages: taskPages)
                        } else {
                            meta = nil
                        }
                        calendarManager.addTask(title: title, date: taskDate, metadata: meta)
                        showingAddTask = false
                    }
                    .disabled(generatedTitle.isEmpty)
                }
            }
        }
    }
}
