//
//  Chord.swift
//  songcaptureV3
//
//  Created by Trevor Elliott on 4/11/2025.
//


import Foundation


struct Chord: Codable, Hashable, Identifiable {
let id: UUID
var root: PitchClass
var quality: Quality
var extensionText: String? // e.g. 7, sus4, add9


init(id: UUID = UUID(), root: PitchClass, quality: Quality = .major, extensionText: String? = nil) {
self.id = id
self.root = root
self.quality = quality
self.extensionText = extensionText
}
var display: String {
root.rawValue + quality.symbol + (extensionText ?? "")
}
}


enum PitchClass: String, Codable, CaseIterable {
case C, CSharp = "C#", D, DSharp = "D#", E, F, FSharp = "F#", G, GSharp = "G#", A, ASharp = "A#", B
}


enum Quality: String, Codable, CaseIterable {
case major, minor, dim, aug, sus
var symbol: String {
switch self {
case .major: return ""
case .minor: return "m"
case .dim: return "dim"
case .aug: return "+"
case .sus: return "sus"
}
}
}