import Foundation
import AVFoundation

/// Portable chord scaffold (I–V–vi–IV) to quickly populate chordEvents.
enum ChordSuggester {
    static func suggestChords(url: URL, songKey: Key, spacingSeconds: Double = 2.0) throws -> [ChordEvent] {
        let file = try AVAudioFile(forReading: url)
        let duration = Double(file.length) / file.fileFormat.sampleRate
        guard duration > 0 else { return [] }

        let progression: [(degree: Int, isMinor: Bool)] = [(1,false),(5,false),(6,true),(4,false)]

        func pitchClass(forDegree degree: Int, in key: Key) -> PitchClass {
            let offsets = [0,2,4,5,7,9,11]
            let pcs: [PitchClass] = [.C,.CSharp,.D,.DSharp,.E,.F,.FSharp,.G,.GSharp,.A,.ASharp,.B]
            let name = key.rawValue.trimmingCharacters(in: .whitespaces).lowercased()
            let rootIndex: Int = {
                switch name {
                case "c": return 0
                case "c#","db": return 1
                case "d": return 2
                case "d#","eb": return 3
                case "e": return 4
                case "f": return 5
                case "f#","gb": return 6
                case "g": return 7
                case "g#","ab": return 8
                case "a": return 9
                case "a#","bb": return 10
                case "b","cb": return 11
                default: return 0
                }
            }()
            let d = max(1, min(7, degree)) - 1
            let semis = (rootIndex + offsets[d]) % 12
            return pcs[semis]
        }

        var out: [ChordEvent] = []
        var t: Double = 0
        var i = 0
        while t < duration {
            let step = progression[i % progression.count]
            let root = pitchClass(forDegree: step.degree, in: songKey)
            out.append(ChordEvent(chord: Chord(root: root, quality: step.isMinor ? .minor : .major), time: t))
            t += spacingSeconds
            i += 1
        }
        return out
    }
}
