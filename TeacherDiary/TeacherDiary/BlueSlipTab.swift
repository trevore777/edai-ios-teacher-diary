import SwiftUI

struct BlueSlipTab: View {
    @EnvironmentObject var store: DiaryStore

    @State private var studentName = ""
    @State private var yearLevel = ""
    @State private var reason: BlueSlipReason = .rtc
    @State private var rtc = true
    @State private var rtcNotes = ""

    @State private var staffName = ""
    @State private var date = Date()
    @State private var timeSent: Date? = nil
    @State private var timeReturned: Date? = nil
    @State private var staffSignature = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Info") {
                    TextField("Name", text: $studentName)
                    TextField("Year Level", text: $yearLevel)
                }
                Section {
                    Picker("Reason", selection: $reason) {
                        ForEach(BlueSlipReason.allCases) { r in Text(r.rawValue).tag(r) }
                    }
                    Toggle("RTC", isOn: $rtc)
                    TextField("RTC Notes", text: $rtcNotes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .disabled(!rtc)
                        .opacity(rtc ? 1 : 0.4)
                } header: {
                    HStack { Text("Reason"); Spacer(); Text("RTC").font(.subheadline).foregroundStyle(.secondary) }
                }
                Section("Staff Info") {
                    TextField("Staff", text: $staffName)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Time Sent", selection: dateBinding($timeSent), displayedComponents: .hourAndMinute)
                    DatePicker("Time Returned", selection: dateBinding($timeReturned), displayedComponents: .hourAndMinute)
                    TextField("Staff Signature", text: $staffSignature)
                }
                Button("Save") { save() }.buttonStyle(.borderedProminent)
            }
            .navigationTitle("New Blue Slip")
        }
    }

    private func dateBinding(_ optional: Binding<Date?>, default defaultDate: Date = Date()) -> Binding<Date> {
        Binding<Date>(get: { optional.wrappedValue ?? defaultDate }, set: { optional.wrappedValue = $0 })
    }

    private func save() {
        guard !studentName.isEmpty, !yearLevel.isEmpty else { return }
        let bs = BlueSlip(studentName: studentName, yearLevel: yearLevel, reason: reason, rtc: rtc, rtcNotes: rtcNotes.isEmpty ? nil : rtcNotes, staffName: staffName, date: date, timeSent: timeSent, timeReturned: timeReturned, staffSignature: staffSignature.isEmpty ? nil : staffSignature)
        store.addBlueSlip(bs)
        studentName = ""; yearLevel = ""; reason = .rtc; rtc = true; rtcNotes = ""
        staffName = ""; date = Date(); timeSent = nil; timeReturned = nil; staffSignature = ""
    }
}
