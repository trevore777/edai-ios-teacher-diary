import SwiftUI

@main
struct TeacherDiaryApp: App {
    @StateObject private var store = DiaryStore()
    var body: some Scene {
        WindowGroup {
            TabView {
                SplashScreenView()
                    .tabItem { Label("Today", systemImage: "sun.max") }
                PCTab()
                    .tabItem { Label("PC", systemImage: "person.3") }
                CalendarTab()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                ObservationTab()
                    .tabItem { Label("Observations", systemImage: "checklist") }
                PDTab()
                    .tabItem { Label("PD", systemImage: "graduationcap") }
                SettingsTab()
                    .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
            }
            .environmentObject(store)
        }
    }
}
