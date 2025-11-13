// Models/SongStore.swift
import Foundation
import Combine   // provides ObservableObject / @Published

@MainActor
final class SongStore: ObservableObject {
    @Published var songs: [Song] = []
    @Published var active: Song = .init()

    private let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("songs.json")
    }()

    init() { load() }

    func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            songs = decoded
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        try? data.write(to: url)
    }

    func addActiveToLibrary() {
        if let idx = songs.firstIndex(where: { $0.id == active.id }) {
            songs[idx] = active
        } else {
            songs.insert(active, at: 0)
        }
        save()
    }

    // Deletion helpers (from earlier step)
    func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { songs[$0] }
        songs.remove(atOffsets: offsets)
        save()
        toDelete.forEach { cleanupFiles(for: $0) }
        ensureValidActive()
    }

    func delete(_ song: Song) {
        if let idx = songs.firstIndex(where: { $0.id == song.id }) {
            songs.remove(at: idx)
            save()
        }
        cleanupFiles(for: song)
        ensureValidActive()
    }

    private func cleanupFiles(for song: Song) {
        if let audio = song.audioURL { try? FileManager.default.removeItem(at: audio) }
        let pdf = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(sanitize(song.title)).pdf")
        if FileManager.default.fileExists(atPath: pdf.path) {
            try? FileManager.default.removeItem(at: pdf)
        }
    }

    private func ensureValidActive() {
        if songs.contains(where: { $0.id == active.id }) == false {
            active = songs.first ?? Song()
        }
    }

    private func sanitize(_ s: String) -> String {
        s.replacingOccurrences(of: "[/\\\\:*?\"<>|]", with: "_", options: .regularExpression)
    }
}
