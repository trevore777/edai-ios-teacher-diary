import SwiftUI
import UniformTypeIdentifiers

struct TranscribeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: SongStore
    @StateObject private var transcriber = SpeechTranscriber()

    // File import
    @State private var showImporter = false
    @State private var importedURL: URL?

    // UI state
    @State private var transcript: String = ""
    @State private var status: String = "Pick an audio file to transcribe."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Transcribe Lyrics")
                    .font(.largeTitle).bold()

                // Import audio
                HStack(spacing: 12) {
                    Button {
                        showImporter = true
                    } label: {
                        Label(importedURL == nil ? "Import Audio" : "Change Audio",
                              systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)

                    if let url = importedURL {
                        Text(url.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // Transcribe
                Button {
                    Task { await doTranscribe() }
                } label: {
                    if transcriber.isTranscribing {
                        Label("Transcribing…", systemImage: "waveform.and.mic")
                    } else {
                        Label("Transcribe from Audio", systemImage: "waveform.and.mic")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(importedURL == nil || transcriber.isTranscribing)

                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                // Lyrics box + Copy
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Lyrics")
                            .font(.headline)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = transcript
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .disabled(transcript.isEmpty)
                    }

                    TextEditor(text: $transcript)
                        .frame(minHeight: 240)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.secondary.opacity(0.2))
                        )
                }

                // Footer actions
                HStack {
                    Button("Close", role: .cancel) { dismiss() }

                    Spacer()

                    Button {
                        createSongInLibrary(from: transcript)
                        dismiss()
                    } label: {
                        Label("Create Song in Library", systemImage: "plus.square.on.square")
                    }
                    .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        // MARK: - File import
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType.audio]) { result in
            switch result {
            case .success(let url):
                // Security-scoped access while copying into our sandbox
                let ok = url.startAccessingSecurityScopedResource()
                defer { if ok { url.stopAccessingSecurityScopedResource() } }

                do {
                    let ext = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
                    let dest = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(ext)

                    try FileManager.default.copyItem(at: url, to: dest)
                    importedURL = dest
                    status = "Ready to transcribe."
                } catch {
                    importedURL = nil
                    status = "Import copy failed: \(error.localizedDescription)"
                }

            case .failure(let err):
                status = "Import failed: \(err.localizedDescription)"
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers (inside struct, outside body)

    private func inferredTitle(from text: String) -> String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "New Song"
        return String(firstLine.prefix(60))
    }

    private func createSongInLibrary(from text: String) {
        var song = Song(title: inferredTitle(from: text))
        song.lyrics = text
        song.chordEvents = []
        store.songs.insert(song, at: 0)
        store.save()
    }

    private func doTranscribe() async {
        guard let url = importedURL else { return }
        status = "Converting audio…"
        do {
            // Convert to speech-friendly WAV in our sandbox
            let wav = try makePCM16MonoWAV(from: url)

            status = "Transcribing…"
            let text = try await transcriber.transcribeFile(url: wav) // uses fallbacks internally
            transcript = text
            status = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "No words detected."
                : "Done."
        } catch {
            transcript = ""
            status = "Transcription failed: \((error as NSError).localizedDescription)"
        }
    }
}
