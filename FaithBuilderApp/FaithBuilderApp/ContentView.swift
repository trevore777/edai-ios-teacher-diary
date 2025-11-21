import SwiftUI

struct ContentView: View {
    @EnvironmentObject var questionStore: QuestionStore
    
    var body: some View {
        TabView {
            TopicListView()
                .tabItem {
                    Label("Topics", systemImage: "book.closed")
                }
            
            SavedQuestionsView()
                .tabItem {
                    Label("Saved", systemImage: "tray.full")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
        }
    }
}

