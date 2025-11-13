import SwiftUI

struct PCTab: View {
    @State private var today = Date()
    @State private var category: PCCategory = PCCategoryScheduler.category(for: Date())
    @State private var currentSuggestion: PCActivity = PCCategoryScheduler.sample(for: Date()).randomElement()!
    @StateObject private var stepStore = StepCountStore()

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    if let info = PCCategoryScheduler.info(for: today) {
                        infoCard(info: info)
                    }

                    if PCCategoryScheduler.isPCDay(today) {
                        // MARK: - Steps Card
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Steps Walked Today", systemImage: "figure.walk.circle.fill")
                                .font(.headline)
                            if stepStore.permissionGranted {
                                Text("\(stepStore.stepsToday) steps")
                                    .font(.title3.bold())
                                    .foregroundColor(.accentColor)
                                Text("Keep moving — every step counts!")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Please enable Health permissions to view step count.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

                        suggestionCard
                        Button {
                            withAnimation {
                                currentSuggestion = PCCategoryScheduler.sample(for: today).randomElement()!
                            }
                        } label: {
                            Label("New Suggestion", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        notPCDayCard
                    }
                }
                .padding()
            }
            .navigationTitle("PC")
            .onAppear {
                refreshForToday()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pastoral Care (PC)")
                .font(.largeTitle.bold())
            Text("Mon • Wed • Thu • Fri • ~10 minutes • Years 7–12")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoCard(info: (title: String, subtitle: String)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(info.title, systemImage: PCCategoryScheduler.symbol(for: category))
                .font(.headline)
            Text(info.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentSuggestion.title)
                .font(.title3.bold())
            if !currentSuggestion.detail.isEmpty {
                Text(currentSuggestion.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if !currentSuggestion.scripture.isEmpty {
                Divider().padding(.vertical, 4)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.secondary)
                    Text(currentSuggestion.scripture)
                        .italic()
                }
            }

            if !currentSuggestion.affirmation.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(.secondary)
                    Text(currentSuggestion.affirmation)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var notPCDayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No PC Today", systemImage: "calendar.badge.exclamationmark")
                .font(.headline)
            Text("PC runs on Monday, Wednesday, Thursday, and Friday. Come back then for a fresh suggestion.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func refreshForToday() {
        today = Date()
        category = PCCategoryScheduler.category(for: today)
        currentSuggestion = PCCategoryScheduler.sample(for: today).randomElement()!
    }
}

// MARK: - CATEGORY SCHEDULER

enum PCCategory: String {
    case affirmation
    case scripture
    case game
    case character
}

enum PCCategoryScheduler {
    /// PC runs Mon (2), Wed (4), Thu (5), Fri (6) in iOS weekday numbering (Sun=1).
    static func isPCDay(_ date: Date) -> Bool {
        let w = Calendar.current.component(.weekday, from: date)
        return w == 2 || w == 4 || w == 5 || w == 6
    }

    /// Mapping:
    /// Mon (2)  -> Affirmation
    /// Wed (4)  -> Scripture & Reflection
    /// Thu (5)  -> Affirmation
    /// Fri (6)  -> Alternate weekly between Game Morning and Character Focus
    static func category(for date: Date) -> PCCategory {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)

        switch weekday {
        case 2: return .affirmation       // Monday
        case 4: return .scripture         // Wednesday
        case 5: return .affirmation       // Thursday
        case 6:
            // Even weekOfYear -> game, odd -> character (or flip if you prefer)
            let week = cal.component(.weekOfYear, from: date)
            return (week % 2 == 0) ? .game : .character
        default:
            // Not a PC day – default to affirmation set so UI still has data if called
            return .affirmation
        }
    }

    /// Returns a human-friendly header & subtitle for the current day/category.
    static func info(for date: Date) -> (title: String, subtitle: String)? {
        guard isPCDay(date) else { return nil }
        let cat = category(for: date)
        switch cat {
        case .affirmation:
            return ("Affirmation & Check-in", "Short gratitude or growth affirmation, quick share around the room.")
        case .scripture:
            return ("Scripture & Reflection", "Read a short verse; ask 1 prompt question for application today.")
        case .game:
            return ("Game Morning", "Fast, inclusive icebreaker that builds connection and positivity.")
        case .character:
            return ("Character Focus", "Discuss a value (e.g., perseverance) and a simple action for the day.")
        }
    }

    /// Icon per category
    static func symbol(for category: PCCategory) -> String {
        switch category {
        case .affirmation: return "heart.text.square.fill"
        case .scripture:   return "book.fill"
        case .game:        return "gamecontroller.fill"
        case .character:   return "star.bubble.fill"
        }
    }

    /// Returns a pool of activities for TODAY based on the schedule.
    static func sample(for date: Date) -> [PCActivity] {
        switch category(for: date) {
        case .affirmation: return PCData.affirmations
        case .scripture:   return PCData.scripture
        case .game:        return PCData.games
        case .character:   return PCData.character
        }
    }
}

// MARK: - DATA MODELS

struct PCActivity: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let scripture: String
    let affirmation: String
}

// MARK: - CONTENT SETS

enum PCData {
    // Affirmation (used twice a week: Mon & Thu)
    static let affirmations: [PCActivity] = [
        PCActivity(
            title: "Gratitude Ripple",
            detail: "Each student shares one thing they’re thankful for this morning. Optional: write one sentence of appreciation to a peer.",
            scripture: "“In every thing give thanks.” — 1 Thessalonians 5:18",
            affirmation: "Today I will look for the good and speak it out."
        ),
        PCActivity(
            title: "Growth Mindset Minute",
            detail: "Quick round: ‘One small step I can take today toward my goal is…’",
            scripture: "“Write the vision, and make it plain.” — Habakkuk 2:2",
            affirmation: "I’m capable, I’m growing, and today is progress."
        ),
        PCActivity(
            title: "Kindness Intention",
            detail: "Students set one kindness action for today (help, include, encourage).",
            scripture: "“Serve one another humbly in love.” — Galatians 5:13",
            affirmation: "My words and actions will lift others."
        )
    ]

    // Scripture & Reflection (used on Wednesday)
    static let scripture: [PCActivity] = [
        PCActivity(
            title: "Light & Example",
            detail: "Read and discuss: ‘What’s one way we can let our light shine at school today?’",
            scripture: "“Let your light so shine before men…” — Matthew 5:16",
            affirmation: ""
        ),
        PCActivity(
            title: "Peace in Pressure",
            detail: "Share calmly: ‘What helps you find peace before a test or busy day?’",
            scripture: "“Be still, and know that I am God.” — Psalm 46:10",
            affirmation: ""
        ),
        PCActivity(
            title: "Trust & Steps",
            detail: "Discuss a small decision today where we can trust God and act wisely.",
            scripture: "“In all thy ways acknowledge him, and he shall direct thy paths.” — Proverbs 3:6",
            affirmation: ""
        )
    ]

    // Game Morning (used on some Fridays)
    static let games: [PCActivity] = [
        PCActivity(
            title: "Would You Rather – Speed Round",
            detail: "Teacher fires 6–8 fun choices; hands up for A/B. Keep it fast and inclusive.",
            scripture: "",
            affirmation: ""
        ),
        PCActivity(
            title: "Emoji Movie Quiz",
            detail: "Show 6 emoji combos; teams guess the movie in 10 seconds.",
            scripture: "",
            affirmation: ""
        ),
        PCActivity(
            title: "Word Chain",
            detail: "In a circle, each student says a word starting with the last letter of previous word. Theme: positive traits.",
            scripture: "",
            affirmation: ""
        )
    ]

    // Character Focus (used on alternating Fridays)
    static let character: [PCActivity] = [
        PCActivity(
            title: "Perseverance in Practice",
            detail: "Each student names one challenge and a small step to persist today.",
            scripture: "“Let us run with patience the race that is set before us.” — Hebrews 12:1",
            affirmation: ""
        ),
        PCActivity(
            title: "Respect in Action",
            detail: "Brainstorm what respect looks/sounds like in class, corridors, and online.",
            scripture: "“As ye would that men should do to you, do ye also to them.” — Luke 6:31",
            affirmation: ""
        ),
        PCActivity(
            title: "Integrity Moments",
            detail: "Share an example of choosing right when no one is watching; set a personal integrity goal.",
            scripture: "“The integrity of the upright shall guide them.” — Proverbs 11:3",
            affirmation: ""
        )
    ]
}
