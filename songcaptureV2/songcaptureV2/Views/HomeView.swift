import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: SongStore
    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            List {
                Section("Library") {
                    ForEach(store.songs) { song in
                        NavigationLink(song.title) {
                            EditorView(song: song)
                                .environmentObject(store)
                        }
                    }
                    .onDelete(perform: store.delete) // swipe-to-delete
                }
                Section {
                    Button {
                        showCapture = true
                    } label: {
                        Label("New Capture", systemImage: "record.circle")
                    }
                }
                // Inside your List in HomeView
                Section("Tools") {
                    NavigationLink {
                        TranscribeView().environmentObject(store)
                    } label: {
                        Label("Transcribe Lyrics", systemImage: "waveform.and.mic")
                    }
                }
                
            }
            .navigationTitle("SongCapture")
            .toolbar { EditButton() }
            .sheet(isPresented: $showCapture) {
                CaptureView().environmentObject(store)
            }
        }
    }
}
