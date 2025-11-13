import SwiftUI

/// Renders chords above words and highlights the current word during playback.
struct LyricRendererView: View {
    let lines: [AlignedLine]
    @Binding var playhead: TimeInterval

    init(lines: [AlignedLine], playhead: Binding<TimeInterval>) {
        self.lines = lines
        self._playhead = playhead
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<lines.count, id: \.self) { i in
                let line = lines[i]

                // Each token = VStack(chord, word), laid out across the page
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    ForEach(line.tokens, id: \.self) { tok in
                        let isNow = playhead >= tok.startTime && playhead < tok.endTime

                        VStack(spacing: 2) {
                            Text(tok.chordAbove ?? " ")
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(.secondary)

                            Text(tok.text)
                                .font(.body)
                                .padding(.horizontal, isNow ? 2 : 0)
                                .background(isNow ? Color.yellow.opacity(0.35) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
    }
}
