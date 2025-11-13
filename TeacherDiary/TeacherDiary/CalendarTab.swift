import SwiftUI
import UniformTypeIdentifiers
import EventKit

// MARK: - Display Mode Enum
enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case month = "Month"
    case week  = "Week"
    var id: String { rawValue }
}

// MARK: - Calendar Tab
struct CalendarTab: View {
    @EnvironmentObject var store: DiaryStore

    @State private var showingImporter = false
    @State private var selectedDate = Date()
    @State private var mode: CalendarDisplayMode = .month
    @State private var showAddEvent = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                    // Top controls
                    HStack {
                        Picker("", selection: $mode) {
                            Text("Month").tag(CalendarDisplayMode.month)
                            Text("Week").tag(CalendarDisplayMode.week)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)

                        Spacer()

                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                    }
                    .padding(.horizontal)

                    // Calendar Display
                    Group {
                        switch mode {
                        case .month:
                            MonthGrid(selectedDate: $selectedDate, events: store.events)
                        case .week:
                            WeekStrip(selectedDate: $selectedDate, events: store.events)
                        }
                    }
                    .padding(.horizontal)

                    // Events list
                    List {
                        Section(header: Text("Events on \(selectedDate.formatted(date: .abbreviated, time: .omitted))")) {
                            ForEach(eventsForDay(selectedDate)) { e in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.title).font(.headline)
                                    if let loc = e.location, !loc.isEmpty {
                                        Text(loc).foregroundColor(.secondary)
                                    }
                                    Text(timeRange(e))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let d = e.detail, !d.isEmpty {
                                        Text(d).font(.subheadline)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                // Floating "Today" button
                Button {
                    selectedDate = Date()
                } label: {
                    Label("Today", systemImage: "calendar")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .shadow(radius: 2)
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        // CSV Importer
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let granted = url.startAccessingSecurityScopedResource()
                defer { if granted { url.stopAccessingSecurityScopedResource() } }

                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    let csv = decodeCSVData(data)
                    let normalized = normalizeNewlines(csv)
                    let imported = CSVImporter.parse(csv: normalized)
                    DispatchQueue.main.async {
                        store.events = imported.sorted { $0.start < $1.start }
                        store.saveEvents()
                    }
                } catch {
                    print("CSV import error:", error.localizedDescription)
                }

            case .failure(let err):
                print("Importer failed:", err.localizedDescription)
            }
        }
        // Add Event Sheet
        .sheet(isPresented: $showAddEvent) {
            AddEventSheet(initialDate: selectedDate) { newEvent, alsoAppleCalendar in
                store.events.append(newEvent)
                store.events.sort { $0.start < $1.start }
                store.saveEvents()

                if alsoAppleCalendar {
                    Task {
                        do { try await EventKitHelper.shared.addToAppleCalendar(event: newEvent) }
                        catch { print("EventKit save failed:", error.localizedDescription) }
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func eventsForDay(_ date: Date) -> [SchoolEvent] {
        let cal = Calendar.current
        return store.events.filter { cal.isDate($0.start, inSameDayAs: date) }
    }

    private func timeRange(_ e: SchoolEvent) -> String {
        if e.allDay { return "All day" }
        if !Calendar.current.isDate(e.start, inSameDayAs: e.end) { return "Multi-day" }
        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        return "\(tf.string(from: e.start)) – \(tf.string(from: e.end))"
    }
}

// MARK: - Month Grid (fixed)
private struct MonthGrid: View {
    @Binding var selectedDate: Date
    let events: [SchoolEvent]

    private var cal: Calendar { Calendar.current }
    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 4), count: 7) }

    var body: some View {
        VStack(spacing: 8) {
            // Title + arrows
            HStack(spacing: 8) {
                Button(action: { moveMonth(-1) }) { Image(systemName: "chevron.left") }
                    .buttonStyle(.bordered)

                Spacer()
                Text(selectedDate.formatted(.dateTime.year().month())).font(.title3).bold()
                Spacer()

                Button(action: { moveMonth(1) }) { Image(systemName: "chevron.right") }
                    .buttonStyle(.bordered)
            }

            // Weekday header
            HStack {
                ForEach(weekdaySymbols(), id: \.self) { wd in
                    Text(wd.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 7x6 grid starting at the first week of the month
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(gridDays(), id: \.self) { day in
                    DayCell(
                        date: day,
                        isCurrentMonth: cal.isDate(day, equalTo: selectedDate, toGranularity: .month),
                        isSelected: cal.isDate(day, inSameDayAs: selectedDate),
                        eventCount: eventsOn(day).count
                    )
                    .onTapGesture { selectedDate = day }
                }
            }
        }
    }

    private func moveMonth(_ delta: Int) {
        if let newDate = cal.date(byAdding: .month, value: delta, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func gridDays() -> [Date] {
        let monthStart = cal.dateInterval(of: .month, for: selectedDate)!.start
        let gridStart = cal.dateInterval(of: .weekOfYear, for: monthStart)!.start
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private func weekdaySymbols() -> [String] {
        let syms = cal.shortWeekdaySymbols
        let startIndex = (cal.firstWeekday - 1 + syms.count) % syms.count
        return Array(syms[startIndex...] + syms[..<startIndex])
    }

    private func eventsOn(_ date: Date) -> [SchoolEvent] {
        events.filter { cal.isDate($0.start, inSameDayAs: date) }
    }
}

// MARK: - Day Cell
private struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let eventCount: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.day()))
                .font(.body)
                .foregroundColor(isCurrentMonth ? .primary : .secondary.opacity(0.5))

            if eventCount > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<min(eventCount, 3), id: \.self) { _ in Circle().frame(width: 5, height: 5) }
                }
                .foregroundColor(.accentColor)
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : .clear)
        )
    }
}

// MARK: - Week Strip
private struct WeekStrip: View {
    @Binding var selectedDate: Date
    let events: [SchoolEvent]
    private var cal: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { moveWeek(-1) }) { Image(systemName: "chevron.left") }
                    .buttonStyle(.bordered)
                Spacer()
                Text(weekTitle(for: selectedDate)).font(.title3).bold()
                Spacer()
                Button(action: { moveWeek(1) }) { Image(systemName: "chevron.right") }
                    .buttonStyle(.bordered)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(daysInWeek(for: selectedDate), id: \.self) { day in
                        let isSel = cal.isDate(day, inSameDayAs: selectedDate)
                        let count = eventsOn(day).count
                        WeekDayPill(day: day, isSelected: isSel, eventCount: count)
                            .onTapGesture { selectedDate = day }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func daysInWeek(for date: Date) -> [Date] {
        let start = cal.dateInterval(of: .weekOfYear, for: date)!.start
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func weekTitle(for date: Date) -> String {
        let interval = cal.dateInterval(of: .weekOfYear, for: date)!
        let s = interval.start.formatted(date: .abbreviated, time: .omitted)
        let e = cal.date(byAdding: .day, value: 6, to: interval.start)!.formatted(date: .abbreviated, time: .omitted)
        return "\(s) – \(e)"
    }

    private func moveWeek(_ delta: Int) {
        if let newDate = cal.date(byAdding: .weekOfYear, value: delta, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func eventsOn(_ date: Date) -> [SchoolEvent] {
        events.filter { cal.isDate($0.start, inSameDayAs: date) }
    }
}

private struct WeekDayPill: View {
    let day: Date
    let isSelected: Bool
    let eventCount: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.caption).foregroundColor(.secondary)
            Text(day.formatted(.dateTime.day())).font(.headline)
            if eventCount > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<min(eventCount, 3), id: \.self) { _ in Circle().frame(width: 5, height: 5) }
                }
                .foregroundColor(.accentColor)
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(width: 60, height: 70)
        .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1))
    }
}

// MARK: - Add Event Sheet
private struct AddEventSheet: View {
    var initialDate: Date
    var onSave: (SchoolEvent, Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var allDay = false
    @State private var start: Date
    @State private var end: Date
    @State private var location = ""
    @State private var category = ""
    @State private var detail = ""
    @State private var alsoAppleCalendar = false

    init(initialDate: Date, onSave: @escaping (SchoolEvent, Bool) -> Void) {
        self.initialDate = initialDate
        self.onSave = onSave
        let startOfDay = Calendar.current.startOfDay(for: initialDate)
        _start = State(initialValue: startOfDay)
        _end = State(initialValue: Calendar.current.date(byAdding: .hour, value: 1, to: startOfDay) ?? startOfDay)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    Toggle("All day", isOn: $allDay)
                    DatePicker("Start", selection: $start, displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                    DatePicker("End", selection: $end, in: start..., displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                    TextField("Location", text: $location)
                    TextField("Category", text: $category)
                    TextField("Notes", text: $detail, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section {
                    Toggle("Also add to Apple Calendar", isOn: $alsoAppleCalendar)
                } footer: {
                    Text("Requires permission to access your device calendar.")
                }
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var s = start
                        var e = end
                        if allDay {
                            s = Calendar.current.startOfDay(for: start)
                            e = Calendar.current.date(byAdding: .day, value: 1, to: s) ?? s
                        }
                        let newEvent = SchoolEvent(
                            title: title.isEmpty ? "Untitled" : title,
                            start: s,
                            end: e,
                            location: location.nilIfEmpty(),
                            category: category.nilIfEmpty(),
                            detail: detail.nilIfEmpty(),
                            allDay: allDay
                        )
                        onSave(newEvent, alsoAppleCalendar)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - EventKit Helper
final class EventKitHelper {
    static let shared = EventKitHelper()
    private let store = EKEventStore()
    private init() {}

    func addToAppleCalendar(event: SchoolEvent) async throws {
        try await requestAccessIfNeeded()

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.title = event.title
        ekEvent.startDate = event.start
        ekEvent.endDate = event.end
        ekEvent.isAllDay = event.allDay
        ekEvent.location = event.location
        ekEvent.notes = [
            event.category.map { "Category: \($0)" },
            event.detail
        ].compactMap { $0 }.joined(separator: "\n")
        ekEvent.calendar = store.defaultCalendarForNewEvents
        try store.save(ekEvent, span: .thisEvent, commit: true)
    }

    private func requestAccessIfNeeded() async throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            return
        case .notDetermined:
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                store.requestAccess(to: .event) { granted, err in
                    if let err = err { cont.resume(throwing: err); return }
                    granted ? cont.resume(returning: ()) :
                        cont.resume(throwing: NSError(domain: "EventKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access not granted"]))
                }
            }
        default:
            throw NSError(domain: "EventKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied in Settings"])
        }
    }
}

// MARK: - Helpers
func decodeCSVData(_ data: Data) -> String {
    if var s = String(data: data, encoding: .utf8) {
        if s.hasPrefix("\u{FEFF}") { s.removeFirst() }
        return s
    }
    if let s = String(data: data, encoding: .utf16LittleEndian)
        ?? String(data: data, encoding: .utf16BigEndian)
        ?? String(data: data, encoding: .unicode) {
        return s
    }
    return String(data: data, encoding: .isoLatin1) ?? ""
}

func normalizeNewlines(_ s: String) -> String {
    s.replacingOccurrences(of: "\r\n", with: "\n")
     .replacingOccurrences(of: "\r", with: "\n")
}

extension String {
    func nilIfEmpty() -> String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
