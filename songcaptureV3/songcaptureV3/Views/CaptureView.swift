// Views/CaptureView.swift
import SwiftUI

struct CaptureView: View {
    @EnvironmentObject var store: SongStore
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var transcriber = SpeechTranscriber()

    @State private var audioURL: URL?
    @State private var isTranscribing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(store.active.title.isEmpty ? "Untitled" : store.active.title)
                    .font(.title2).bold()

                HStack(spacing: 24) {
                    Button(action: toggleRecord) {
                        Label(recorder.isRecording ? "Stop" : "Record",
                              systemImage: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.title)
                    }
                    .buttonStyle(.borderedProminent)

                    if let audioURL {
                        ShareLink(item: audioURL) {
                            Label("Share Audio", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                if recorder.isRecording {
                    Text(String(format: "%.1fs", recorder.currentTime))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Divider()

                Button {
                    Task { await transcribe() }
                } label: {
                    Label("Transcribe to Lyrics", systemImage: "text.viewfinder")
                }
                .disabled(audioURL == nil || isTranscribing)

                if isTranscribing {
                    ProgressView("Transcribing…")
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { titleEditor }
            }
        }
    }

    // MARK: - Title editor
    @ViewBuilder
    private var titleEditor: some View {
        TextField("Title",
                  text: Binding(
                    get: { store.active.title },
                    set: { store.active.title = $0 }
                  ))
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 220)
    }

    // MARK: - Actions
    private func toggleRecord() {
        if recorder.isRecording {
            recorder.stop()
        } else {
            do {
                let url = try recorder.startRecording()
                audioURL = url
                store.active.audioURL = url
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func transcribe() async {
        guard let url = audioURL else { return }
        do {
            try await transcriber.requestAuth()
            isTranscribing = true
            let lines = try await transcriber.transcribe(url: url)
            store.active.lyrics = lines
            store.addActiveToLibrary()
            isTranscribing = false
        } catch {
            self.errorMessage = error.localizedDescription
            isTranscribing = false
        }
    }
}
