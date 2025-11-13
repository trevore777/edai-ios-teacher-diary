import SwiftUI

@main
struct SongCaptureApp: App {
    @StateObject private var store = SongStore()   // create once at the top

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)         // inject into the root
        }
    }
}
