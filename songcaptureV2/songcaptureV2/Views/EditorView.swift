import SwiftUI
import AVFoundation
import Speech

struct EditorView: View {
    @EnvironmentObject var store: SongStore
    @State var song: Song

    @State private var player: AVAudioPlayer?
    @State private var playhead: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var statusText: String = ""

    @State private var showLyrics: Bool = true
    @State private var showLyricsPrompt: Bool = false
    @State private var alignedLines: [AlignedLine] = []

    @StateObject private var transcriber = SpeechTranscriber()
    @State private var showTranscribeError: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: Binding(
                        get: { activeSong.wrappedValue.title },
                        set: { activeSong.wrappedValue.title = $0; store.save() }
                    ))
                    .textFieldStyle(.roundedBorder)

                    HStack(spacing: 12) {
                        Picker("Key", selection: Binding(
                            get: { activeSong.wrappedValue.key },
                            set: { activeSong.wrappedValue.key = $0; store.save() }
                        )) {
                            ForEach(Key.allCases) { k in Text(k.rawValue).tag(k) }
                        }
                        .pickerStyle(.menu)

                        Spacer()

                        Toggle("Show Lyrics", isOn: $showLyrics)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }

                HStack(spacing: 12) {
                    Text("File: \(activeSong.wrappedValue.audioURL?.lastPathComponent ?? "—")")
                    Divider()
                    Text("Duration: \(String(format: "%.1fs", duration))")
                    Divider()
                    Text("Chords: \(activeSong.wrappedValue.chordEvents.count)")
                    Divider()
                    Text("Lyrics: \(activeSong.wrappedValue.lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "none" : "ok")")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                if let _ = activeSong.wrappedValue.audioURL {
                    transport
                } else {
                    Text("No audio for this song yet. Record in New Capture.")
                        .foregroundStyle(.secondary)
                }

                if showLyrics {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lyrics").font(.headline)
                        TextEditor(text: Binding(
                            get: { activeSong.wrappedValue.lyrics },
                            set: { activeSong.wrappedValue.lyrics = $0; store.save() }
                        ))
                        .frame(minHeight: 160)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary.opacity(0.2)))
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                    }
                    // In the Lyrics section of EditorView (keep TextEditor)
                    HStack {
                        Button {
                            if let clip = UIPasteboard.general.string {
                                activeSong.wrappedValue.lyrics = clip
                                store.save()
                            }
                        } label: {
                            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                        }

                        Spacer()

                        Button(role: .destructive) {
                            activeSong.wrappedValue.lyrics = ""
                            store.save()
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        guard let url = activeSong.wrappedValue.audioURL else { return }
                        do {
                            let events = try ChordSuggester.suggestChords(
                                url: url,
                                songKey: activeSong.wrappedValue.key,
                                spacingSeconds: 2.0
                            )
                            activeSong.wrappedValue.chordEvents = events
                            store.save()

                            let dur = duration > 0 ? duration : (player?.duration ?? forceReadDuration(url: url))
                            alignedLines = AlignmentEngine.align(
                                lyrics: activeSong.wrappedValue.lyrics,
                                chordEvents: events,
                                duration: dur
                            )
                        } catch {
                            print("Suggest error:", error.localizedDescription)
                        }
                    } label: {
                        Label("Auto-Suggest Chords (beta)", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let dur = duration > 0 ? duration :
                            (activeSong.wrappedValue.audioURL.flatMap { forceReadDuration(url: $0) } ?? 0)
                        alignedLines = AlignmentEngine.align(
                            lyrics: activeSong.wrappedValue.lyrics,
                            chordEvents: activeSong.wrappedValue.chordEvents,
                            duration: dur
                        )
                    } label: {
                        Label("Align Chords to Lyrics", systemImage: "text.append")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        Task {
                            guard let source = activeSong.wrappedValue.audioURL else { return }
                            do {
                                let pcmURL = try makePCM16MonoWAV(from: source)   // your converter
                                let text = try await transcriber.transcribeFile(url: pcmURL)
                                activeSong.wrappedValue.lyrics = text
                                store.save()

                                let dur = duration > 0 ? duration : (player?.duration ?? forceReadDuration(url: source))
                                alignedLines = AlignmentEngine.align(
                                    lyrics: text,
                                    chordEvents: activeSong.wrappedValue.chordEvents,
                                    duration: dur
                                )
                            } catch {
                                let nse = error as NSError
                                transcriber.lastError = "\(nse.domain) (\(nse.code)) – \(nse.localizedDescription)"
                                showTranscribeError = true
                            }
                        }
                    } label: {
                        if transcriber.isTranscribing {
                            Label("Transcribing…", systemImage: "waveform.and.mic")
                        } else {
                            Label("Transcribe from Recording", systemImage: "waveform.and.mic")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(transcriber.isTranscribing)


                }
                .alert("Transcription failed", isPresented: $showTranscribeError, actions: {
                    Button("OK", role: .cancel) { }
                }, message: {
                    Text(transcriber.lastError ?? "Unknown error")
                })

                if !alignedLines.isEmpty {
                    GroupBox("Lyrics + Chords (live)") {
                        LyricRendererView(lines: alignedLines, playhead: $playhead)
                            .padding(.top, 4)
                    }
                } else {
                    Text("Tip: Record → Transcribe → Auto-Suggest → Align, then press Play.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(activeSong.wrappedValue.title)
        .onAppear {
            preparePlayerIfPossible()
            if activeSong.wrappedValue.lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showLyrics = true
                showLyricsPrompt = true
            }
        }
        .alert("Add lyrics?", isPresented: $showLyricsPrompt) {
            Button("Paste") {
                if let clip = UIPasteboard.general.string {
                    activeSong.wrappedValue.lyrics = clip
                    store.save()
                }
            }
            Button("Type Manually") { }
            Button("Later", role: .cancel) { showLyrics = false }
        } message: {
            Text("Paste from clipboard or tap “Transcribe from Recording” to auto-fill lyrics.")
        }
        .onChange(of: activeSong.wrappedValue.lyrics) { _, _ in
            let dur = duration > 0 ? duration : (player?.duration ?? 0)
            alignedLines = AlignmentEngine.align(
                lyrics: activeSong.wrappedValue.lyrics,
                chordEvents: activeSong.wrappedValue.chordEvents,
                duration: dur
            )
        }
        .onChange(of: activeSong.wrappedValue.chordEvents) { _, _ in
            let dur = duration > 0 ? duration : (player?.duration ?? 0)
            alignedLines = AlignmentEngine.align(
                lyrics: activeSong.wrappedValue.lyrics,
                chordEvents: activeSong.wrappedValue.chordEvents,
                duration: dur
            )
        }
        .onChange(of: activeSong.wrappedValue.audioURL) { _, _ in
            preparePlayerIfPossible()
        }
        .onDisappear { stop() }
    }

    private var transport: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button(action: toggle) {
                    Label(isPlaying ? "Pause" : "Play",
                          systemImage: isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Text(String(format: "%.1f / %.1fs", playhead, duration))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Slider(value: Binding(
                    get: { playhead },
                    set: { newVal in seek(to: newVal) }
                ), in: 0...(duration > 0 ? duration : 1))
            }
            if !statusText.isEmpty {
                Text(statusText).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private var isPlaying: Bool { player?.isPlaying == true }

    private func preparePlayerIfPossible() {
        guard let url = activeSong.wrappedValue.audioURL else {
            statusText = "No audio URL."; return
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            statusText = "Audio file not found at \(url.lastPathComponent)."; return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? forceReadDuration(url: url)
            startTimer()
            statusText = "Ready."
        } catch {
            statusText = "Player error: \(error.localizedDescription)"
        }
    }


    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            playhead = player?.currentTime ?? 0
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }


    private func toggle() {
        if isPlaying { player?.pause() } else { player?.play() }
    }

    private func seek(to t: TimeInterval) {
        guard let player else { return }
        player.currentTime = max(0, min(t, player.duration))
        playhead = player.currentTime
        if !isPlaying { player.play() }
    }

    private func stop() {
        player?.stop()
        player = nil
        timer?.invalidate()
        timer = nil
    }

    private func forceReadDuration(url: URL) -> TimeInterval {
        if let file = try? AVAudioFile(forReading: url) {
            return Double(file.length) / file.fileFormat.sampleRate
        }
        return 0
    }

    private var activeSong: Binding<Song> {
        if let idx = store.songs.firstIndex(where: { $0.id == song.id }) {
            return Binding(
                get: { store.songs[idx] },
                set: { store.songs[idx] = $0; store.save() }
            )
        } else {
            return Binding(
                get: { store.active },
                set: { store.active = $0; store.addActiveToLibrary() }
            )
        }
    }
}
