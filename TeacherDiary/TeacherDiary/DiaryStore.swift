import Foundation
import SwiftUI

final class DiaryStore: ObservableObject {
    @Published var events: [SchoolEvent] = []
    @Published var observations: [Observation] = []
    @Published var blueSlips: [BlueSlip] = []

    private let fm = FileManager.default
    private var docs: URL { fm.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    private var eventsURL: URL { docs.appendingPathComponent("events.json") }
    private var obsURL: URL { docs.appendingPathComponent("observations.json") }
    private var bsURL: URL { docs.appendingPathComponent("blueslips.json") }

    init() { loadAll() }

    private func loadAll() {
        events = load(from: eventsURL) ?? []
        observations = load(from: obsURL) ?? []
        blueSlips = load(from: bsURL) ?? []
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        if let data = try? JSONEncoder().encode(value) { try? data.write(to: url) }
    }

    func saveEvents() { save(events, to: eventsURL) }
    func saveObservations() { save(observations, to: obsURL) }
    func saveBlueSlips() { save(blueSlips, to: bsURL) }

    // Observations
    func addObservation(_ obs: Observation) {
        observations.insert(obs, at: 0)
        saveObservations()
    }

    // BlueSlips
    func addBlueSlip(_ bs: BlueSlip) {
        blueSlips.insert(bs, at: 0)
        saveBlueSlips()
    }

    // Filters
    enum RangeFilter: String, CaseIterable, Identifiable {
        case all = "All", day = "Day", week = "Week", month = "Month", year = "Year"
        var id: String { rawValue }
    }

    func filteredObservations(range: RangeFilter, search: String) -> [Observation] {
        let base = observations
        let now = Date()
        let cal = Calendar.current

        let filteredByRange: [Observation] = {
            switch range {
            case .all: return base
            case .day: return base.filter { cal.isDate($0.createdAt, inSameDayAs: now) }
            case .week:
                let interval = cal.dateInterval(of: .weekOfYear, for: now)!
                return base.filter { interval.contains($0.createdAt) }
            case .month:
                let interval = cal.dateInterval(of: .month, for: now)!
                return base.filter { interval.contains($0.createdAt) }
            case .year:
                let interval = cal.dateInterval(of: .year, for: now)!
                return base.filter { interval.contains($0.createdAt) }
            }
        }()

        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return filteredByRange }
        return filteredByRange.filter {
            $0.studentName.localizedCaseInsensitiveContains(trimmed) ||
            $0.className.localizedCaseInsensitiveContains(trimmed) ||
            $0.behaviour.rawValue.localizedCaseInsensitiveContains(trimmed) ||
            ($0.note ?? "").localizedCaseInsensitiveContains(trimmed)
        }
    }
}
