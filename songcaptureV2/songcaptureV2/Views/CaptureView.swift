import SwiftUI
import Combine
import AVFoundation

struct CaptureView: View {
    @EnvironmentObject var store: SongStore
    @StateObject private var recorder = AudioRecorder()

    @State private var audioURL: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Text("Title").font(.footnote).foregroundStyle(.secondary)
                    TextField("Untitled", text: Binding(
                        get: { store.active.title },
                        set: { store.active.title = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    Button(action: toggleRecord) {
                        Label(recorder.isRecording ? "Stop" : "Record",
                              systemImage: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)

                    Text(String(format: "%.1fs", recorder.currentTime))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 70, alignment: .leading)

                    if let audioURL {
                        ShareLink(item: audioURL) {
                            Label("Share Audio", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                if let error { Text(error).foregroundStyle(.red) }

                Spacer()
            }
            .padding()
            .navigationTitle("New Capture")
        }
    }

    // Views/CaptureView.swift
    private func toggleRecord() {
        if recorder.isRecording {
            recorder.stop()
            // after stop, ensure we persist the final URL
            if let url = recorder.lastFileURL {
                audioURL = url
                store.active.audioURL = url
                if store.active.title.trimmingCharacters(in: .whitespaces).isEmpty {
                    store.active.title = url.deletingPathExtension().lastPathComponent
                }
                store.addActiveToLibrary() // ✅ save/update after a successful stop
            }
        } else {
            do {
                _ = try recorder.startRecording()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

}
