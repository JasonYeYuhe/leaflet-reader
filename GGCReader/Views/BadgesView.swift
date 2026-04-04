import SwiftUI
import SwiftData

struct BadgesCard: View {
    let allLogs: [ReadingLog]
    let books: [Book]
    let currentStreak: Int
    let bestStreak: Int
    let dailyPageGoal: Int

    @State private var selectedBadge: Badge?
    @State private var showingPaywall = false
    var storeManager = StoreManager.shared

    private static var freeBadgeLimit: Int { StoreManager.freeBadgeLimit }

    private var stats: BadgeStats {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: allLogs) { cal.startOfDay(for: $0.date) }

        return BadgeStats(
            totalPages: allLogs.reduce(0) { $0 + $1.pagesRead },
            totalBooks: books.count,
            finishedBooks: books.filter(\.isFinished).count,
            daysRead: Set(allLogs.map { cal.startOfDay(for: $0.date) }).count,
            bestSingleDay: grouped.values.map { $0.reduce(0) { $0 + $1.pagesRead } }.max() ?? 0,
            weekendDaysRead: Set(allLogs.compactMap { log -> Date? in
                let day = cal.startOfDay(for: log.date)
                return cal.isDateInWeekend(day) ? day : nil
            }).count,
            earlyBirdDays: Set(allLogs.compactMap { log -> Date? in
                cal.component(.hour, from: log.date) < 9 ? cal.startOfDay(for: log.date) : nil
            }).count,
            nightOwlDays: Set(allLogs.compactMap { log -> Date? in
                let hour = cal.component(.hour, from: log.date)
                return (hour >= 22 || hour < 5) ? cal.startOfDay(for: log.date) : nil
            }).count,
            distinctAuthors: Set(books.map(\.author)).subtracting([""]).count,
            goalMetDays: dailyPageGoal > 0 ? grouped.values.filter { logs in
                logs.reduce(0) { $0 + $1.pagesRead } >= dailyPageGoal
            }.count : 0,
            bestStreak: bestStreak
        )
    }

    private var badges: [Badge] {
        buildBadges(from: stats)
    }

    private var unlockedCount: Int {
        badges.filter(\.isUnlocked).count
    }

    private func isProBadge(_ badge: Badge) -> Bool {
        guard let index = badges.firstIndex(where: { $0.id == badge.id }) else { return false }
        return index >= Self.freeBadgeLimit && !storeManager.isPro
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundStyle(.yellow)
                Text("Badges")
                    .font(.headline)
                Spacer()
                Text("\(unlockedCount)/\(badges.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if let badge = selectedBadge {
                HStack(spacing: 8) {
                    Text(badge.icon)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(badge.name)
                            .font(.caption.bold())
                        Text(badge.requirement)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isProBadge(badge) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    } else if badge.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(10)
                .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 10) {
                ForEach(badges) { badge in
                    badgeItem(badge, locked: isProBadge(badge))
                }
            }

            if !storeManager.isPro {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Unlock all badges with Pro")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingPaywall) {
                    PaywallView()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func badgeItem(_ badge: Badge, locked: Bool = false) -> some View {
        VStack(spacing: 4) {
            if locked {
                Text(badge.icon)
                    .font(.system(size: 28))
                    .opacity(0.3)
                    .overlay {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
            } else {
                Text(badge.isUnlocked ? badge.icon : "🔒")
                    .font(.system(size: 28))
                    .opacity(badge.isUnlocked ? 1 : 0.4)
                    .scaleEffect(badge.isUnlocked ? 1 : 0.85)
            }
            Text(badge.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(locked ? .tertiary : (badge.isUnlocked ? .primary : .secondary))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(badge.name))
        .accessibilityValue(locked ? Text("Pro only") : (badge.isUnlocked ? Text("Unlocked") : Text("Locked")))
        .accessibilityHint(Text(badge.requirement))
        .onTapGesture {
            if locked {
                showingPaywall = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedBadge?.id == badge.id {
                        selectedBadge = nil
                    } else {
                        selectedBadge = badge
                        HapticManager.selection()
                    }
                }
            }
        }
    }
}
