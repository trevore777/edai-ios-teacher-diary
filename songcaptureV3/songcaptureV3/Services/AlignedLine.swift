//
//  AlignedLine.swift
//  songcaptureV3
//
//  Created by Trevor Elliott on 4/11/2025.
//


import Foundation


struct AlignedLine: Identifiable, Hashable {
let id = UUID()
var text: String
var chordAbove: String? // combined chord symbol placed above first char of the word
}


enum AlignmentEngine {
/// Aligns chord events to nearest lyric segment (by timestamp) and returns lines with chord symbols above words.
static func align(lyrics: [LyricLine], chordEvents: [ChordEvent]) -> [[AlignedLine]] {
guard !lyrics.isEmpty else { return [] }
let chords = chordEvents.sorted { $0.time < $1.time }
var out: [[AlignedLine]] = []
for line in lyrics {
var aligned: [AlignedLine] = []
for seg in line.segments {
let nearest = chords.min(by: { abs($0.time - seg.startTime) < abs($1.time - seg.startTime) })
let chordSym = nearest.map { $0.chord.display }
aligned.append(.init(text: seg.text, chordAbove: chordSym))
}
out.append(aligned)
}
return out
}
}