// songcaptureV3App.swift
import SwiftUI

@main
struct songcaptureV3App: App {
    @StateObject private var store = SongStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)   // <-- makes SongStore available to all views
        }
    }
}
