//
//  SettingsTab.swift
//  TeacherDiary
//
//  Created by Trevor Elliott on 13/11/2025.
//


import SwiftUI
import UIKit

// MARK: - Notifications your other views can listen to (optional)

extension Notification.Name {
    /// Posted when the user taps "Reset Calendar Data" in Settings.
    static let teacherDiaryCalendarReset = Notification.Name("TeacherDiaryCalendarReset")
    /// Posted when the user taps "Reset All Local Data".
    static let teacherDiaryFullReset = Notification.Name("TeacherDiaryFullReset")
}

// MARK: - Settings Tab

struct SettingsTab: View {
    @State private var showConfirmResetCalendar = false
    @State private var showConfirmResetAll = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var devMode = false
    @State private var devTapCount = 0
    
    var body: some View {
        NavigationView {
            Form {
                dataSection
                aboutSection
                
                if devMode {
                    developerSection
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Sections
    
    private var dataSection: some View {
        Section(header: Text("Data Management")) {
            Button(role: .destructive) {
                showConfirmResetCalendar = true
            } label: {
                Label("Reset Calendar Data", systemImage: "calendar.badge.exclamationmark")
            }
            .confirmationDialog(
                "Remove all imported calendar data?",
                isPresented: $showConfirmResetCalendar,
                titleVisibility: .visible
            ) {
                Button("Remove Calendar Data", role: .destructive) {
                    resetCalendarData()
                }
                Button("Cancel", role: .cancel) { }
            }
            
            Button(role: .destructive) {
                showConfirmResetAll = true
            } label: {
                Label("Reset ALL Local Data", systemImage: "trash")
            }
            .confirmationDialog(
                "This will delete ALL locally stored TeacherDiary data (PD, observations, calendar CSV, etc.). This cannot be undone.",
                isPresented: $showConfirmResetAll,
                titleVisibility: .visible
            ) {
                Button("Reset All Data", role: .destructive) {
                    resetAllLocalData()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .alert("Done", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.headline)
                    .onTapGesture {
                        devTapCount += 1
                        if devTapCount >= 5 {
                            devMode.toggle()
                            devTapCount = 0
                        }
                    }
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("FaithfulTeacher / TeacherDiary is designed and developed by Trevor David Elliott. Modern development tools, including AI-assisted programming, were used to enhance productivity. All final design, content, and implementation are the intellectual property of the developer.")
                .font(.footnote)
            
            HStack {
                Text("Copyright")
                Spacer()
                Text("© 2025 Trevor David Elliott\nAll rights reserved.")
                    .multilineTextAlignment(.trailing)
                    .font(.footnote)
            }
            
            Button {
                openURL("https://teachermadeapps.com/teacherdiary")
            } label: {
                HStack {
                    Text("Website")
                    Spacer()
                    Text("teachermadeapps.com")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                openURL("mailto:support@teachermadeapps.com?subject=TeacherDiary%20Support")
            } label: {
                HStack {
                    Text("Support Email")
                    Spacer()
                    Text("support@teachermadeapps.com")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var developerSection: some View {
        Section(header: Text("Developer Tools")) {
            Button {
                listDocumentDirectory()
            } label: {
                Label("List Documents Directory in Console", systemImage: "terminal")
            }
            
            Button {
                print("TeacherDiary dev mode is ON. Version \(appVersion) (\(buildNumber))")
            } label: {
                Label("Log App Info", systemImage: "ladybug")
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Remove calendar-related local files and notify app.
    private func resetCalendarData() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        // Try common calendar file names you’ve used
        let possibleCalendarFiles = [
            "school_calendar.csv",
            "calendar.csv",
            "events.csv",
            "calendar_events.json"
        ]
        
        for name in possibleCalendarFiles {
            let url = docs.appendingPathComponent(name)
            if fm.fileExists(atPath: url.path) {
                try? fm.removeItem(at: url)
            }
        }
        
        // Notify the rest of the app (CalendarTab can observe this if you want)
        NotificationCenter.default.post(name: .teacherDiaryCalendarReset, object: nil)
        
        alertMessage = "Calendar data has been cleared. Imported school events will no longer appear until you import again."
        showAlert = true
    }
    
    /// Remove all local JSON & CSV files for a completely clean state.
    private func resetAllLocalData() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        if let files = try? fm.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
            for file in files {
                let ext = file.pathExtension.lowercased()
                if ext == "json" || ext == "csv" {
                    try? fm.removeItem(at: file)
                }
            }
        }
        
        NotificationCenter.default.post(name: .teacherDiaryFullReset, object: nil)
        
        alertMessage = "All local TeacherDiary data has been deleted. This is ideal before an App Store upload or fresh start."
        showAlert = true
    }
    
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "TeacherDiary"
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
    
    private func listDocumentDirectory() {
        let fm = FileManager.default
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first,
           let files = try? fm.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
            print("📁 TeacherDiary Documents directory:")
            for f in files {
                print(" - \(f.lastPathComponent)")
            }
        } else {
            print("📁 Could not read Documents directory.")
        }
    }
}
