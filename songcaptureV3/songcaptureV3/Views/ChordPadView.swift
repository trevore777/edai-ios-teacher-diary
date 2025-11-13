//
//  ChordPadView.swift
//  songcaptureV3
//
//  Created by Trevor Elliott on 4/11/2025.
//


import SwiftUI


struct ChordPadView: View {
@Binding var chordEvents: [ChordEvent]
@Binding var playhead: TimeInterval
private let roots: [PitchClass] = [.C,.D,.E,.F,.G,.A,.B]
var body: some View {
VStack(alignment: .leading) {
Text("Tap chords while listening").font(.footnote).foregroundStyle(.secondary)
HStack {
ForEach(roots, id: \.self) { r in
Button(r.rawValue) { add(r, .major) }
.buttonStyle(.bordered)
}
}
HStack {
ForEach(roots, id: \.self) { r in
Button(r.rawValue + "m") { add(r, .minor) }
.buttonStyle(.bordered)
}
}
}
}
private func add(_ root: PitchClass, _ quality: Quality) {
chordEvents.append(ChordEvent(chord: .init(root: root, quality: quality), time: playhead))
}
}