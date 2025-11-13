//
//  Song.swift
//  songcaptureV3
//
//  Created by Trevor Elliott on 4/11/2025.
//


import Foundation


struct Song: Identifiable, Codable, Equatable {
let id: UUID
var title: String
var key: Key
var bpm: Int?
var createdAt: Date
var audioURL: URL?
var lyrics: [LyricLine] // ordered lines with segments
var chordEvents: [ChordEvent] // chord taps with timestamp (sec)


init(id: UUID = UUID(), title: String = "Untitled", key: Key = .G, bpm: Int? = nil, createdAt: Date = .now, audioURL: URL? = nil, lyrics: [LyricLine] = [], chordEvents: [ChordEvent] = []) {
self.id = id
self.title = title
self.key = key
self.bpm = bpm
self.createdAt = createdAt
self.audioURL = audioURL
self.lyrics = lyrics
self.chordEvents = chordEvents
}
}


struct LyricLine: Codable, Hashable {
var segments: [LyricSegment] // each has text and startTime
}


struct LyricSegment: Codable, Hashable {
var text: String
var startTime: TimeInterval // seconds from start of audio
}


struct ChordEvent: Codable, Hashable, Identifiable {
let id: UUID
var chord: Chord
var time: TimeInterval // seconds from start
init(id: UUID = UUID(), chord: Chord, time: TimeInterval) {
self.id = id
self.chord = chord
self.time = time
}
}


enum Key: String, Codable, CaseIterable, Identifiable {
case C, G, D, A, E, B, FSharp = "F#", CSharp = "C#", F, Bb = "Bb", Eb = "Eb", Ab = "Ab"
var id: String { rawValue }
}