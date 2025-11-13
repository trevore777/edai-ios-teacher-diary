import SwiftUI
import CoreLocation

struct SplashScreenView: View {
    @EnvironmentObject var store: DiaryStore
    @StateObject private var weather = WeatherVM()
    @State private var now = Date()

    @State private var verseText: String = ""
    @State private var verseRef: String = ""
    private let bible = BibleAPI()

    // Times for forecast samples
    private let targetTimes: [TargetSlot] = [
        .init(hour: 7, minute: 0, label: "7:00"),
        .init(hour: 11, minute: 30, label: "11:30"),
        .init(hour: 15, minute: 0, label: "3:00")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerHero
                weatherRow
                if !weather.statusNote.isEmpty {
                    Text(weather.statusNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                scriptureCard
                agendaCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(colors: [Color(.systemBlue).opacity(0.1), Color(.systemBackground)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .onAppear {
            weather.start()
            now = Date()
            Task {
                do {
                    let v = try await bible.fetchVerseOfTheDay()
                    verseText = v.text
                    verseRef = v.ref
                } catch {
                    verseText = "This is the day which the LORD hath made; we will rejoice and be glad in it."
                    verseRef = "Psalm 118:24 (KJV)"
                }
            }
        }
    }

    // MARK: Header
    private var headerHero: some View {
        VStack(spacing: 6) {
            Text("TeacherDiary")
                .font(.system(size: 34, weight: .bold, design: .serif))
            Text("Organize • Reflect • Inspire")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(now.formatted(date: .complete, time: .omitted))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
    }

    // MARK: Weather
    private var weatherRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Today’s Weather", systemImage: "cloud.sun")
                    .font(.headline)
                Spacer()
                Button {
                    weather.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(weather.isLoading)
            }
            if let summary = weather.summary(for: targetTimes) {
                HStack(spacing: 12) {
                    ForEach(summary, id: \.label) { slot in
                        WeatherPill(label: slot.label, temp: slot.temp, code: slot.code)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else if weather.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Text("Weather unavailable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    // MARK: Scripture
    private var scriptureCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Scripture of the Day", systemImage: "book")
                .font(.headline)
            if verseText.isEmpty {
                ProgressView().tint(.secondary)
            } else {
                Text("“\(verseText)”").font(.callout)
                Text("— \(verseRef)").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    // MARK: Agenda
    private var agendaCard: some View {
        let todays = todaysEvents()
        return VStack(alignment: .leading, spacing: 8) {
            Label("Today’s Agenda", systemImage: "checklist")
                .font(.headline)
            if todays.isEmpty {
                Text("No events today.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(todays) { e in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "calendar").foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.title).font(.subheadline).bold()
                            HStack(spacing: 8) {
                                Text(timeRange(e))
                                if let loc = e.location, !loc.isEmpty { Text("• \(loc)") }
                            }
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            if let d = e.detail, !d.isEmpty { Text(d).font(.caption) }
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    // MARK: Agenda helpers
    private func todaysEvents() -> [SchoolEvent] {
        let cal = Calendar.current
        return store.events.filter { cal.isDate($0.start, inSameDayAs: Date()) }
            .sorted { $0.start < $1.start }
    }

    private func timeRange(_ e: SchoolEvent) -> String {
        if e.allDay { return "All day" }
        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        return "\(tf.string(from: e.start)) – \(tf.string(from: e.end))"
    }
}

// MARK: - Components
private struct WeatherPill: View {
    let label: String
    let temp: Double
    let code: Int
    var body: some View {
        VStack(spacing: 6) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Image(systemName: WeatherIcon.sfSymbolFromOWM(id: code)).imageScale(.large)
            Text(temp.isNaN ? "–" : "\(Int(round(temp)))°")
                .font(.headline)
        }
        .padding(10)
        .frame(height: 80)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}
