//
//  InlineLyricsView.swift
//  songcaptureV3
//
//  Created by Trevor Elliott on 4/11/2025.
//


import SwiftUI

/// Renders one song line with chords inline above the following word using baseline offset.
struct InlineLyricsView: View {
    let line: [AlignedLine]

    var body: some View {
        Text(attributedLine(line))
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }

    private func attributedLine(_ line: [AlignedLine]) -> AttributedString {
        var out = AttributedString()
        for w in line {
            if let chord = w.chordAbove, !chord.trimmingCharacters(in: .whitespaces).isEmpty {
                var chordAttr = AttributedString(chord)
                chordAttr.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
                chordAttr.baselineOffset = 8 // lift chord above lyric baseline
                chordAttr.foregroundColor = .secondary
                out += chordAttr
            }
            var space = AttributedString(" ")
            space.font = .system(size: 14)
            out += space

            var wordAttr = AttributedString(w.text)
            wordAttr.font = .system(size: 16)
            out += wordAttr

            out += AttributedString(" ") // spacing between words
        }
        return out
    }
}
