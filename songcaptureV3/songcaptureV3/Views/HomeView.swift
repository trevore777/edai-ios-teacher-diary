import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: SongStore
    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            List {
                Section("Library") {
                    ForEach(store.songs) { song in
                        NavigationLink(song.title) { EditorView(song: song) }
                    }
                    .onDelete(perform: store.delete) // ← swipe-to-delete
                }
                Section {
                    Button { showCapture = true } label: {
                        Label("New Capture", systemImage: "record.circle")
                    }
                }
            }
            .navigationTitle("SongCapture")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { EditButton() } // ← edit mode
            }
            .sheet(isPresented: $showCapture) { CaptureView() }
        }
    }
}
