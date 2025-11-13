import SwiftUI
import UniformTypeIdentifiers
import UIKit
import PhotosUI

// MARK: - MODEL

struct PDEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var title: String
    var provider: String
    var mode: PDMode
    var hours: Double
    var apstDomains: Set<APSTDomain> // QCT/APST 1..7
    var notes: String
    var evidenceLink: String? // URL text or drive link
    var evidenceImages: [String] = [] // local file paths to saved images in Documents/
}

enum PDMode: String, Codable, CaseIterable, Identifiable {
    case workshop, onlineCourse, conference, schoolBased, mentoring, professionalReading, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .workshop: return "Workshop"
        case .onlineCourse: return "Online Course"
        case .conference: return "Conference"
        case .schoolBased: return "School-based PD"
        case .mentoring: return "Mentoring/Coaching"
        case .professionalReading: return "Professional Reading"
        case .other: return "Other"
        }
    }
}

enum APSTDomain: String, Codable, CaseIterable, Identifiable, Hashable {
    case d1 = "1: Know students & how they learn"
    case d2 = "2: Know content & how to teach it"
    case d3 = "3: Plan for & implement effective teaching & learning"
    case d4 = "4: Create & maintain supportive & safe learning environments"
    case d5 = "5: Assess, provide feedback & report on student learning"
    case d6 = "6: Engage in professional learning"
    case d7 = "7: Engage professionally with colleagues, parents/carers & the community"

    var id: String { rawValue }
    var short: String {
        switch self {
        case .d1: return "APST 1"
        case .d2: return "APST 2"
        case .d3: return "APST 3"
        case .d4: return "APST 4"
        case .d5: return "APST 5"
        case .d6: return "APST 6"
        case .d7: return "APST 7"
        }
    }
}

// MARK: - TARGET HOURS STORE (UserDefaults per year)

enum TargetHoursStore {
    static func target(for year: Int) -> Double {
        let key = "pd_target_hours_\(year)"
        let v = UserDefaults.standard.double(forKey: key)
        return v > 0 ? v : 20.0 // default 20 hrs
    }
    static func setTarget(_ hours: Double, for year: Int) {
        let key = "pd_target_hours_\(year)"
        UserDefaults.standard.set(hours, forKey: key)
    }
}

// MARK: - STORE (JSON persistence)

final class PDStore: ObservableObject {
    @Published var entries: [PDEntry] = [] {
        didSet { save() }
    }

    private let filename = "pd_entries.json"

    init() {
        load()
    }

    func add(_ e: PDEntry) {
        entries.append(e)
        entries.sort { $0.date > $1.date }
    }

    func update(_ e: PDEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == e.id }) else { return }
        entries[idx] = e
        entries.sort { $0.date > $1.date }
    }

    func delete(at offsets: IndexSet, in filtered: [PDEntry]) {
        let ids = offsets.map { filtered[$0].id }
        entries.removeAll { ids.contains($0.id) }
    }

    func totalHours(for year: Int) -> Double {
        entries
            .filter { Calendar.current.component(.year, from: $0.date) == year }
            .map(\.hours)
            .reduce(0, +)
    }

    // MARK: Persistence
    private func url() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(filename)
    }

    private func load() {
        do {
            let data = try Data(contentsOf: url())
            let decoded = try JSONDecoder().decode([PDEntry].self, from: data)
            self.entries = decoded.sorted { $0.date > $1.date }
        } catch {
            self.entries = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: url(), options: [.atomic, .completeFileProtection])
        } catch {
            print("PD save failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - VIEW

struct PDTab: View {
    @StateObject private var store = PDStore()
    @State private var showForm = false
    @State private var editEntry: PDEntry? = nil
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var exportURL: URL? = nil
    @State private var showExportSheet = false

    // target hours
    @State private var showTargetSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                headerBar

                let filtered = store.entries.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }

                if filtered.isEmpty {
                    contentEmptyState
                } else {
                    List {
                        Section(header: Text("Entries (\(filtered.count))")) {
                            ForEach(filtered) { e in
                                Button {
                                    editEntry = e
                                    showForm = true
                                } label: {
                                    PDRow(entry: e)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { idx in store.delete(at: idx, in: filtered) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("PD Records")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showForm = true } label: { Label("Add PD", systemImage: "plus") }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: 12) {
                        Button { exportPDF() } label: { Label("Export PDF", systemImage: "doc.richtext") }
                        Button { exportCSV() } label: { Label("Export CSV", systemImage: "tablecells") }
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                PDFormView(
                    entry: editEntry ?? PDEntry(date: Date(), title: "", provider: "", mode: .workshop, hours: 1.0, apstDomains: [.d6], notes: "", evidenceLink: nil),
                    onSave: { newOrEdited in
                        if let _ = editEntry { store.update(newOrEdited) } else { store.add(newOrEdited) }
                        editEntry = nil
                    }
                )
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    DocumentShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showTargetSheet) {
                TargetHoursSheet(selectedYear: $selectedYear)
            }
        }
    }

    // MARK: Header with Progress
    private var headerBar: some View {
        VStack(spacing: 8) {
            HStack {
                YearPicker(selectedYear: $selectedYear)
                Spacer()
                Button {
                    showTargetSheet = true
                } label: {
                    Label("Target", systemImage: "target")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            // Progress
            let total = store.totalHours(for: selectedYear)
            let target = TargetHoursStore.target(for: selectedYear)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "clock.badge.checkmark")
                    Text("\(String(format: "%.1f", total)) / \(String(format: "%.0f", target)) hrs")
                        .fontWeight(.semibold)
                }
                ProgressView(value: min(target == 0 ? 0 : total/target, 1.0))
                    .tint(total >= target ? .green : .blue)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }

    private var contentEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .imageScale(.large)
            Text("No PD records for \(selectedYear)")
                .font(.headline)
            Text("Tap “+” to add your first PD entry. Align to APST domains and include hours for QCT.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 40)
    }

    // MARK: Exports
    private func exportPDF() {
        let items = store.entries.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
        let url = PDFExporter.renderQCTReport(year: selectedYear, entries: items)
        exportURL = url
        showExportSheet = true
    }

    private func exportCSV() {
        let items = store.entries.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
        let url = CSVExporter.generate(year: selectedYear, entries: items)
        exportURL = url
        showExportSheet = true
    }
}

// MARK: - ROW

private struct PDRow: View {
    let entry: PDEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.title).font(.headline)
                Spacer()
                Text(String(format: "%.1f h", entry.hours))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text(entry.provider)
                Text("•")
                Text(entry.mode.label)
                Text("•")
                Text(entry.date, style: .date)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !entry.notes.isEmpty {
                Text(entry.notes).font(.caption)
                    .lineLimit(2)
            }

            if !entry.apstDomains.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(entry.apstDomains).sorted(by: { $0.short < $1.short }), id: \.self) { d in
                        Text(d.short)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                    }
                }
            }

            if !entry.evidenceImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.evidenceImages, id: \.self) { path in
                            if let img = UIImage(contentsOfFile: path) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                            }
                        }
                    }
                }
                .frame(height: 64)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - FORM (with PhotosPicker)

private struct PDFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State var entry: PDEntry
    var onSave: (PDEntry) -> Void
    @State private var showValidation = false

    @State private var photoSelections: [PhotosPickerItem] = []

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $entry.date, displayedComponents: .date)
                    TextField("Title (e.g., Differentiation Strategies)", text: $entry.title)
                    TextField("Provider (e.g., QCAA, AISQ)", text: $entry.provider)

                    Picker("Mode", selection: $entry.mode) {
                        ForEach(PDMode.allCases) { m in Text(m.label).tag(m) }
                    }
                    HStack {
                        Text("Hours")
                        Spacer()
                        TextField("e.g., 1.5", value: $entry.hours, formatter: NumberFormatter.decimal1)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("APST Domains") {
                    APSTPicker(selected: $entry.apstDomains)
                }

                Section("Notes / Reflection") {
                    TextEditor(text: $entry.notes)
                        .frame(minHeight: 120)
                }

                Section("Evidence") {
                    TextField("Link to slides/certificate (URL)", text: Binding(
                        get: { entry.evidenceLink ?? "" },
                        set: { entry.evidenceLink = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    PhotosPicker(selection: $photoSelections, maxSelectionCount: 6, matching: .images) {
                        Label("Add Certificate Photos", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: photoSelections) { _, items in
                        Task { await importImages(from: items) }
                    }

                    if !entry.evidenceImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(entry.evidenceImages, id: \.self) { path in
                                    if let img = UIImage(contentsOfFile: path) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .frame(height: 90)
                    }
                }
            }
            .navigationTitle(entry.id == UUID() ? "New PD" : "Edit PD")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validate() {
                            onSave(entry)
                            dismiss()
                        } else {
                            showValidation = true
                        }
                    }
                }
            }
            .alert("Please complete Title and Hours.", isPresented: $showValidation) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    private func validate() -> Bool {
        !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && entry.hours > 0
    }

    private func documentsDir() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func uniqueImageURL() -> URL {
        documentsDir().appendingPathComponent("pd_img_\(UUID().uuidString).jpg")
    }

    private func saveJPEG(_ image: UIImage, to url: URL) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: url, options: [.atomic, .completeFileProtection])
        }
    }

    private func resizeForThumb(_ img: UIImage, maxSide: CGFloat = 160) -> UIImage {
        let size = img.size
        let scale = maxSide / max(size.width, size.height)
        if scale >= 1 { return img }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        img.draw(in: CGRect(origin: .zero, size: newSize))
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out ?? img
    }

    private func importImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                let resized = resizeForThumb(img)
                let url = uniqueImageURL()
                saveJPEG(resized, to: url)
                entry.evidenceImages.append(url.path)
            }
        }
        photoSelections.removeAll()
    }
}

private struct APSTPicker: View {
    @Binding var selected: Set<APSTDomain>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(APSTDomain.allCases) { d in
                Toggle(isOn: Binding(
                    get: { selected.contains(d) },
                    set: { isOn in
                        if isOn {
                            _ = selected.insert(d) // ignore returned tuple
                        } else {
                            selected.remove(d)
                        }
                    }
                )) {
                    VStack(alignment: .leading) {
                        Text(d.short).bold()
                        Text(d.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - YEAR PICKER

private struct YearPicker: View {
    @Binding var selectedYear: Int
    var body: some View {
        HStack(spacing: 6) {
            Button { selectedYear -= 1 } label: { Image(systemName: "chevron.left") }
            Text("\(selectedYear)").font(.headline).frame(minWidth: 60)
            Button { selectedYear += 1 } label: { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - TARGET HOURS SHEET

private struct TargetHoursSheet: View {
    @Binding var selectedYear: Int
    @State private var target: Double = 20.0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Year") {
                    HStack(spacing: 6) {
                        Button { selectedYear -= 1 } label: { Image(systemName: "chevron.left") }
                        Text("\(selectedYear)").font(.headline)
                        Button { selectedYear += 1 } label: { Image(systemName: "chevron.right") }
                    }
                }
                Section("Target Hours") {
                    HStack {
                        Slider(value: $target, in: 5...80, step: 1)
                        Text("\(Int(target)) h").frame(width: 60, alignment: .trailing)
                    }
                    Text("Set your QCT annual PD hours goal for this year.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("PD Target")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        TargetHoursStore.setTarget(target, for: selectedYear)
                        dismiss()
                    }
                }
            }
            .onAppear {
                target = TargetHoursStore.target(for: selectedYear)
            }
        }
    }
}

// MARK: - EXPORT: PDF & CSV (with image thumbnails)

enum PDFExporter {
    static func renderQCTReport(year: Int, entries: [PDEntry]) -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("PD_Report_\(year).pdf")

        let pageWidth: CGFloat = 595.2  // A4 @72dpi
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 36

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        do {
            try renderer.writePDF(to: url, withActions: { ctx in
                func newPage() { ctx.beginPage() }
                func drawText(_ text: String, at point: CGPoint, font: UIFont) {
                    (text as NSString).draw(at: point, withAttributes: [.font: font])
                }

                var y = margin

                // Cover / summary
                newPage()
                drawText("Professional Development Report", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 22, weight: .bold)); y += 30
                drawText("Year \(year)", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 14)); y += 20

                let total = entries.map(\.hours).reduce(0, +)
                drawText("Total Hours: \(String(format: "%.1f", total))    Entries: \(entries.count)", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 12)); y += 28

                // Table header
                drawText("Date        Hours  Title  (Provider, Mode, APST)", at: CGPoint(x: margin, y: y), font: .monospacedSystemFont(ofSize: 11, weight: .semibold)); y += 16

                let mono = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
                let df = DateFormatter(); df.dateStyle = .medium

                for e in entries.sorted(by: { $0.date < $1.date }) {
                    func ensure(_ needed: CGFloat) {
                        if y + needed > pageHeight - margin {
                            newPage()
                            y = margin
                        }
                    }

                    ensure(80)

                    let dateStr = df.string(from: e.date)
                    let apstStr = e.apstDomains.map { $0.short }.sorted().joined(separator: ", ")
                    let line1 = String(format: "%-12s  %4.1f  %@", (dateStr as NSString).utf8String!, e.hours, e.title)
                    drawText(line1, at: CGPoint(x: margin, y: y), font: mono); y += 14

                    let line2 = "   \(e.provider), \(e.mode.label)\(apstStr.isEmpty ? "" : ", \(apstStr)")"
                    drawText(line2, at: CGPoint(x: margin, y: y), font: mono); y += 12

                    if !e.notes.isEmpty {
                        drawWrapped(text: "   Notes: \(e.notes)", atX: margin, y: &y, pageWidth: pageWidth, margin: margin, font: mono, ctx: ctx)
                    } else {
                        y += 6
                    }

                    // Thumbnails row
                    if !e.evidenceImages.isEmpty {
                        ensure(90)
                        var x = margin
                        let thumbH: CGFloat = 64
                        for path in e.evidenceImages.prefix(6) { // limit per entry
                            if let img = UIImage(contentsOfFile: path) {
                                let ratio = img.size.width / img.size.height
                                let w = thumbH * ratio
                                ensure(thumbH + 20)
                                img.draw(in: CGRect(x: x, y: y, width: w, height: thumbH))
                                x += w + 8
                            }
                        }
                        y += thumbH + 16
                    }
                }
            })
        } catch {
            print("PDF write failed: \(error.localizedDescription)")
        }
        return url
    }

    private static func drawWrapped(text: String, atX x: CGFloat, y: inout CGFloat, pageWidth: CGFloat, margin: CGFloat, font: UIFont, ctx: UIGraphicsPDFRendererContext) {
        let maxWidth = pageWidth - margin * 2
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attr: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraphStyle]
        let rect = CGRect(x: x, y: y, width: maxWidth, height: .greatestFiniteMagnitude)
        let bounding = (text as NSString).boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attr, context: nil)
        (text as NSString).draw(with: rect, options: .usesLineFragmentOrigin, attributes: attr, context: nil)
        y += ceil(bounding.height) + 8
    }
}

enum CSVExporter {
    static func generate(year: Int, entries: [PDEntry]) -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("PD_Export_\(year).csv")

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var rows: [String] = []
        rows.append("Date,Hours,Title,Provider,Mode,APST,Notes,EvidenceLink,ImagesCount")
        for e in entries.sorted(by: { $0.date < $1.date }) {
            let apst = e.apstDomains.map { $0.short }.sorted().joined(separator: "; ")
            func csvEscape(_ s: String) -> String {
                let esc = s.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(esc)\""
            }
            let row = [
                df.string(from: e.date),
                String(format: "%.1f", e.hours),
                csvEscape(e.title),
                csvEscape(e.provider),
                csvEscape(e.mode.label),
                csvEscape(apst),
                csvEscape(e.notes),
                csvEscape(e.evidenceLink ?? ""),
                String(e.evidenceImages.count)
            ].joined(separator: ",")
            rows.append(row)
        }

        do {
            try rows.joined(separator: "\n").data(using: .utf8)?.write(to: url, options: .atomic)
        } catch {
            print("CSV write failed: \(error.localizedDescription)")
        }
        return url
    }
}

// MARK: - UTIL

private struct DocumentShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

private extension NumberFormatter {
    static var decimal1: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 1
        return nf
    }
}
