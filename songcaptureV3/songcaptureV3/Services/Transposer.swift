//
//  Transposer.swift
//  songcaptureV3
//
//  Created by Trevor Elliott on 4/11/2025.
//


import Foundation


struct Transposer {
private static let order: [PitchClass] = [.C,.CSharp,.D,.DSharp,.E,.F,.FSharp,.G,.GSharp,.A,.ASharp,.B]
static func transpose(_ chord: Chord, semitones: Int) -> Chord {
let idx = order.firstIndex(of: chord.root) ?? 0
let newIdx = (idx + semitones + order.count) % order.count
return Chord(root: order[newIdx], quality: chord.quality, extensionText: chord.extensionText)
}
static func semitones(from: Key, to: Key) -> Int {
func pc(_ k: Key) -> PitchClass {
switch k {
case .C: return .C
case .G: return .G
case .D: return .D
case .A: return .A
case .E: return .E
case .B: return .B
case .FSharp: return .FSharp
case .CSharp: return .CSharp
case .F: return .F
case .Bb: return .ASharp
case .Eb: return .DSharp
case .Ab: return .GSharp
}
}
let a = order.firstIndex(of: pc(from)) ?? 0
let b = order.firstIndex(of: pc(to)) ?? 0
return b - a
}
/// Returns capo fret to **play in G** while sounding in the song's key.
static func capoForG(songKey: Key) -> Int {
let gIdx = order.firstIndex(of: .G) ?? 7
let targetIdx: Int = {
switch songKey {
case .C: return order.firstIndex(of: .C)!
case .G: return order.firstIndex(of: .G)!
case .D: return order.firstIndex(of: .D)!
case .A: return order.firstIndex(of: .A)!
case .E: return order.firstIndex(of: .E)!
case .B: return order.firstIndex(of: .B)!
case .FSharp: return order.firstIndex(of: .FSharp)!
case .CSharp: return order.firstIndex(of: .CSharp)!
case .F: return order.firstIndex(of: .F)!
case .Bb: return order.firstIndex(of: .ASharp)!
case .Eb: return order.firstIndex(of: .DSharp)!
case .Ab: return order.firstIndex(of: .GSharp)!
}
}()
var capo = targetIdx - gIdx
if capo < 0 { capo += order.count }
return capo % 12
}
}