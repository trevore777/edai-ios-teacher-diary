import SwiftUI

@main
struct QuickViewBibleStudyApp: App {
    @StateObject private var questionStore = QuestionStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(questionStore)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
        #endif
    }
}
