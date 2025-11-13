import Foundation
import Combine

/// Model for a single song or recording
struct Song: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = "Untitled"
    var key: Key = .C
    var lyrics: String = ""
    var audioURL: URL?
    var chordEvents: [ChordEvent] = []

    static let empty = Song()
}

/// Basic musical key enum
enum Key: String, CaseIterable, Codable, Identifiable {
    case C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B
    var id: String { rawValue }
}

/// Simple chord structure used by ChordSuggester
struct Chord: Codable, Equatable {
    var root: PitchClass
    var quality: Quality

    enum Quality: String, Codable {
        case major, minor
    }

    var display: String {
        switch quality {
        case .major: return root.rawValue
        case .minor: return "\(root.rawValue)m"
        }
    }
}

/// Note name enum (12-tone)
enum PitchClass: String, Codable, CaseIterable {
    case C, CSharp = "C#", D, DSharp = "D#", E, F, FSharp = "F#",
         G, GSharp = "G#", A, ASharp = "A#", B
}

/// When a chord appears in the timeline
struct ChordEvent: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var chord: Chord
    var time: TimeInterval
}

/// Central store managing all songs
@MainActor
final class SongStore: ObservableObject {
    @Published var songs: [Song] = []
    @Published var active: Song = .empty

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("songs.json")
    }()

    init() {
        load()
    }

    /// Add or update the current active song in the library
    func addActiveToLibrary() {
        if let index = songs.firstIndex(where: { $0.id == active.id }) {
            songs[index] = active
        } else {
            songs.append(active)
        }
        save()
    }

    /// Save all songs to JSON
    func save() {
        do {
            let data = try JSONEncoder().encode(songs)
            try data.write(to: saveURL)
        } catch {
            print("Save error:", error.localizedDescription)
        }
    }

    /// Load songs from JSON (if exists)
    func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            songs = try JSONDecoder().decode([Song].self, from: data)
        } catch {
            print("Load error:", error.localizedDescription)
        }
    }
}
