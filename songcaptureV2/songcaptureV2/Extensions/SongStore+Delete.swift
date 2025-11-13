import Foundation
import Combine   // if your SongStore uses @Published or ObservableObject

// Make sure this matches your actual store class name —
// e.g., SongStore, LibraryStore, or whatever you called it.
extension SongStore {
    /// Delete songs at given index set, removing audio files from disk too.
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let s = songs[index]
            if let url = s.audioURL, FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        songs.remove(atOffsets: offsets)
        save()
    }

    /// Delete a specific song by its ID.
    func delete(_ song: Song) {
        if let i = songs.firstIndex(where: { $0.id == song.id }) {
            delete(at: IndexSet(integer: i))
        }
    }
}
