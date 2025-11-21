import SwiftUI
import UIKit

// MARK: - Model

enum BehaviourCategory: String, Codable, CaseIterable, Identifiable {
    case playingGames = "Playing games"
    case talking = "Talking"
    case offTask = "Off-task"
    case deviceMisuse = "Device misuse"
    case excellence = "Excellence"
    case other = "Other"

    var id: String { rawValue }
}

struct ObservationRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var studentName: String
    var className: String
    var behaviour: BehaviourCategory
    var notes: String
}

// MARK: - Store (JSON persistence)

final class ObservationStore: ObservableObject {
    @Published var records: [ObservationRecord] = [] {
        didSet { save() }
    }

    private let filename = "observations.json"

    init() {
        load()
    }

    func add(_ record: ObservationRecord) {
        records.append(record)
        sort()
    }

    func update(_ record: ObservationRecord) {
        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[idx] = record
        sort()
    }

    func delete(at offsets: IndexSet, in filtered: [ObservationRecord]) {
        let ids = offsets.map { filtered[$0].id }
        records.removeAll { ids.contains($0.id) }
    }

    private func sort() {
        records.sort { $0.date > $1.date }
    }

    // MARK: Persistence

    private func fileURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(filename)
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL())
            let decoded = try JSONDecoder().decode([ObservationRecord].self, from: data)
            self.records = decoded.sorted { $0.date > $1.date }
        } catch {
            self.records = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL(), options: [.atomic, .completeFileProtection])
        } catch {
            print("Observation save failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Main View

struct ObservationTab: View {
    @StateObject private var store = ObservationStore()

    // filters
    @State private var selectedBehaviourFilter: BehaviourCategory? = nil
    @State private var searchText: String = ""

    // add/edit
    @State private var showForm = false
    @State private var editingRecord: ObservationRecord? = nil

    // detail (sheet with optional item – avoids blank sheet)
    @State private var selectedRecord: ObservationRecord? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                filterBar

                let filtered = filteredRecords

                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { record in
                            Button {
                                selectedRecord = record
                            } label: {
                                ObservationRow(record: record)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { idx in
                            store.delete(at: idx, in: filtered)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Observations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingRecord = nil
                        showForm = true
                    } label: { Label("New", systemImage: "plus") }
                }
            }
            // New sheet style: binds directly to selectedRecord
            .sheet(item: $selectedRecord) { record in
                ObservationDetailView(record: record)
            }
            .sheet(isPresented: $showForm) {
                ObservationForm(
                    record: editingRecord ?? ObservationRecord(
                        date: Date(),
                        studentName: "",
                        className: "",
                        behaviour: .offTask,
                        notes: ""
                    )
                ) { newOrEdited in
                    if let _ = editingRecord {
                        store.update(newOrEdited)
                    } else {
                        store.add(newOrEdited)
                    }
                    editingRecord = nil
                }
            }
        }
    }

    // MARK: - Filters

    private var filteredRecords: [ObservationRecord] {
        store.records.filter { record in
            if let behaviour = selectedBehaviourFilter, record.behaviour != behaviour {
                return false
            }
            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                let token = searchText.lowercased()
                let haystack = (record.studentName + " " + record.className).lowercased()
                if !haystack.contains(token) { return false }
            }
            return true
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search by student or class", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedBehaviourFilter = nil
                    } label: {
                        Text("All")
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(
                                Capsule().fill(selectedBehaviourFilter == nil
                                               ? Color.accentColor.opacity(0.2)
                                               : Color(.secondarySystemBackground))
                            )
                    }

                    ForEach(BehaviourCategory.allCases) { behaviour in
                        Button {
                            selectedBehaviourFilter = behaviour
                        } label: {
                            Text(behaviour.rawValue)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(
                                    Capsule().fill(selectedBehaviourFilter == behaviour
                                                   ? Color.accentColor.opacity(0.2)
                                                   : Color(.secondarySystemBackground))
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No observations recorded")
                .font(.headline)
            Text("Tap “+” to log a new observation. Use filters to quickly find and email records when needed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 40)
    }
}

// MARK: - Row

private struct ObservationRow: View {
    let record: ObservationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.studentName.isEmpty ? "(No name)" : record.studentName)
                    .font(.headline)
                Spacer()
                Text(record.behaviour.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color(.tertiarySystemFill)))
            }
            HStack(spacing: 6) {
                Text(record.className.isEmpty ? "(No class)" : record.className)
                Text("•")
                Text(record.date, style: .date)
                Text(record.date, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Form (New / Edit)

private struct ObservationForm: View {
    @Environment(\.dismiss) private var dismiss

    @State var record: ObservationRecord
    var onSave: (ObservationRecord) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Student") {
                    TextField("Student name", text: $record.studentName)
                    TextField("Class (e.g., 7 DigiTech)", text: $record.className)
                }

                Section("Details") {
                    DatePicker("Date & Time", selection: $record.date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Behaviour", selection: $record.behaviour) {
                        ForEach(BehaviourCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section("Observation Notes") {
                    TextEditor(text: $record.notes)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Observation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(record)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Detail + Email

private struct ObservationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: ObservationRecord

    @State private var showEmailError = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    HStack {
                        Text(record.studentName.isEmpty ? "(No name)" : record.studentName)
                            .font(.title2.bold())
                        Spacer()
                    }
                    Text(record.className.isEmpty ? "(No class)" : record.className)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Behaviour: \(record.behaviour.rawValue)")
                        .font(.subheadline)

                    Text("Date: \(formattedDate(record.date))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text("Observation Notes")
                    .font(.headline)
                ScrollView {
                    Text(record.notes.isEmpty ? "(No notes recorded)" : record.notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                Button {
                    if !emailRTC(for: record) {
                        showEmailError = true
                    }
                } label: {
                    Label("Email to RTC", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Observation Detail")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    }
                }
            }
            .alert("Unable to open Mail", isPresented: $showEmailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please ensure the Mail app is set up on this device, then try again.")
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    /// Returns true if it successfully asked the system to open Mail.
    @discardableResult
    private func emailRTC(for record: ObservationRecord) -> Bool {
        let primary = "ResponsibleThinkingProcessRC@kingscollege.qld.edu.au"
        let secondary = "reedycreekrtc@kingscollege.qld.edu.au"

        let toField = "\(primary),\(secondary)"

        let subject = "Observation – \(record.studentName) – \(record.behaviour.rawValue)"

        let body = """
        Dear RTC team,

        Please see the observation details below:

        Student: \(record.studentName)
        Class: \(record.className)
        Date/Time: \(formattedDate(record.date))
        Behaviour: \(record.behaviour.rawValue)

        Observation notes:
        \(record.notes.isEmpty ? "(No notes provided)" : record.notes)

        Kind regards,
        Mr Elliott
        telliott@kingscollege.qld.edu.au
        """

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(toField)?subject=\(encodedSubject)&body=\(encodedBody)"

        guard let url = URL(string: urlString) else { return false }
        guard UIApplication.shared.canOpenURL(url) else { return false }

        UIApplication.shared.open(url)
        return true
    }
}
