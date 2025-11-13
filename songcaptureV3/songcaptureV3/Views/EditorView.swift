// Views/EditorView.swift
import SwiftUI
import AVFoundation

struct EditorView: View {
    @EnvironmentObject var store: SongStore
    @Environment(\.dismiss) private var dismiss

    @State var song: Song

    // Playback & UI state
    @State private var aligned: [[AlignedLine]] = []
    @State private var player: AVAudioPlayer?
    @State private var playhead: TimeInterval = 0
    @State private var tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let url = song.audioURL {
                    transport(url: url)
                }

                ChordPadView(chordEvents: $song.chordEvents, playhead: $playhead)
                    .padding(.vertical, 8)

                Button {
                    align()
                } label: {
                    Label("Align Chords to Lyrics", systemImage: "text.append")
                }

                GroupBox("Lyrics (Inline Chords)") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<aligned.count, id: \.self) { i in
                            InlineLyricsView(line: aligned[i])
                        }
                    }
                }

                ExportView(song: song, aligned: aligned)
            }
            .padding()
        }
        .navigationTitle(song.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete this song?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                player?.stop()
                store.delete(song)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the song from your library and deletes audio/PDF files.")
        }
        .onReceive(tick) { _ in
            playhead = player?.currentTime ?? 0
        }
        .onDisappear {
            player?.stop(); player = nil
        }
        .onChange(of: song) { _ in
            store.addActiveToLibrary()
        }
    }

    // MARK: - Header (key + capo info)
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Key", selection: $song.key) {
                    ForEach(Key.allCases) { k in
                        Text(k.rawValue).tag(k)
                    }
                }
                .pickerStyle(.menu)

                let capo = Transposer.capoForG(songKey: song.key)
                (Text("Capo to play in G: ") + Text("\(capo)").bold())
            }
        }
    }

    // MARK: - Transport (prepare / toggle / UI)
    @ViewBuilder
    private func transport(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: { toggle(url) }) {
                    Label(player?.isPlaying == true ? "Pause" : "Play",
                          systemImage: player?.isPlaying == true ? "pause.fill" : "play.fill")
                }
                Text(String(format: "%.1fs", playhead)).monospacedDigit()
            }
            .onAppear { prepare(url) }
        }
    }

    private func prepare(_ url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        } catch {
            print("Player error: \(error)")
        }
    }

    private func toggle(_ url: URL) {
        if player?.isPlaying == true {
            player?.pause()
        } else {
            if player == nil { prepare(url) }
            player?.play()
        }
    }

    // MARK: - Alignment
    private func align() {
        aligned = AlignmentEngine.align(lyrics: song.lyrics, chordEvents: song.chordEvents)
    }
}
