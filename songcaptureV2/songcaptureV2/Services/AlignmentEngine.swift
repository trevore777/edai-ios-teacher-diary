import Foundation

struct AlignedToken: Hashable, Codable {
    var text: String
    var chordAbove: String?
    var startTime: TimeInterval
    var endTime: TimeInterval
}

struct AlignedLine: Hashable, Codable {
    var tokens: [AlignedToken]
}

enum AlignmentEngine {
    static func align(lyrics: String,
                      chordEvents: [ChordEvent],
                      duration: TimeInterval) -> [AlignedLine] {

        // Build chord time markers (start … chords … end)
        let sorted = chordEvents.sorted(by: { $0.time < $1.time })
        var markers: [(time: TimeInterval, chord: String?)] = []
        markers.append((0, nil))
        for e in sorted { markers.append((max(0, e.time), e.chord.display)) }
        markers.append((max(0, duration), nil))

        // If NO lyrics: show chord-only rows (across the page)
        let hasAnyLyrics = lyrics
            .components(separatedBy: .newlines)
            .contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        if !hasAnyLyrics {
            var out: [AlignedLine] = []
            let perRow = 6
            var row: [AlignedToken] = []

            for i in 0..<(markers.count - 1) {
                let st = markers[i].time
                let en = markers[i+1].time
                let chord = markers[i].chord
                row.append(AlignedToken(text: "•", chordAbove: chord, startTime: st, endTime: en))
                if row.count == perRow {
                    out.append(AlignedLine(tokens: row))
                    row.removeAll()
                }
            }
            if !row.isEmpty { out.append(AlignedLine(tokens: row)) }
            return out
        }

        // Lyrics present: split into lines and words
        let rawLines = lyrics.components(separatedBy: .newlines)
        var result: [AlignedLine] = []
        var markerIndex = 0

        for line in rawLines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // blank line – keep timing continuity
                let st = markers[max(0, min(markerIndex, markers.count - 2))].time
                let en = markers[min(markers.count - 1, markerIndex + 1)].time
                result.append(AlignedLine(tokens: [
                    AlignedToken(text: "", chordAbove: nil, startTime: st, endTime: en)
                ]))
                continue
            }

            var words = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            if words.isEmpty { words = [" "] }

            var iWord = 0
            while iWord < words.count && markerIndex < markers.count - 1 {
                let startT = markers[markerIndex].time
                let endT   = markers[markerIndex + 1].time
                let chord  = markers[markerIndex].chord

                // distribute words across remaining windows
                let remainingWindows = max(1, (markers.count - 1) - markerIndex)
                let remainingWords   = words.count - iWord
                let wordsInThisWindow = max(1, remainingWords / remainingWindows)

                let jWord = min(words.count, iWord + wordsInThisWindow)
                let slice = Array(words[iWord..<jWord])

                let sliceDuration = max(0.05, endT - startT)
                let totalChars = max(1, slice.reduce(0) { $0 + $1.count })

                var tokens: [AlignedToken] = []
                var cursor = startT
                for (idx, w) in slice.enumerated() {
                    let portion: TimeInterval =
                        (idx == slice.count - 1)
                        ? (startT + sliceDuration - cursor)
                        : sliceDuration * (TimeInterval(w.count) / TimeInterval(totalChars))

                    tokens.append(AlignedToken(
                        text: w,
                        chordAbove: idx == 0 ? chord : nil,  // print chord once at start of window
                        startTime: cursor,
                        endTime: cursor + max(0.01, portion)
                    ))
                    cursor = tokens.last!.endTime
                }

                result.append(AlignedLine(tokens: tokens))
                iWord = jWord
                markerIndex += 1
            }

            // leftover words (after last chord window): place to the end
            if iWord < words.count {
                let startT = markerIndex < markers.count ? markers[markerIndex].time : duration
                let endT   = duration
                let slice  = Array(words[iWord..<words.count])
                let totalChars = max(1, slice.reduce(0) { $0 + $1.count })

                var tokens: [AlignedToken] = []
                var cursor = startT
                for (idx, w) in slice.enumerated() {
                    let portion: TimeInterval =
                        (idx == slice.count - 1)
                        ? (endT - cursor)
                        : (endT - startT) * (TimeInterval(w.count) / TimeInterval(totalChars))

                    tokens.append(AlignedToken(
                        text: w,
                        chordAbove: (idx == 0 && markerIndex < markers.count) ? markers[markerIndex].chord : nil,
                        startTime: cursor,
                        endTime: cursor + max(0.01, portion)
                    ))
                    cursor = tokens.last!.endTime
                }
                result.append(AlignedLine(tokens: tokens))
            }
        }

        return result
    }
}
