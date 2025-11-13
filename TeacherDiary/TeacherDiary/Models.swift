import Foundation

// MARK: - Calendar / Events
struct SchoolEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var start: Date
    var end: Date
    var location: String?
    var category: String?
    var detail: String?
    var allDay: Bool
}

// MARK: - Student Tracker
enum BehaviourType: String, CaseIterable, Codable, Identifiable {
    case playingGames = "Playing games"
    case talking = "Talking"
    case offTask = "Off task"
    case late = "Late"
    case deviceMisuse = "Device misuse"
    case excellence = "Excellence"
    var id: String { rawValue }
}

struct Observation: Identifiable, Codable {
    var id = UUID()
    var studentName: String
    var className: String
    var behaviour: BehaviourType
    var note: String?
    var createdAt: Date
}

// MARK: - Blue Slip
enum BlueSlipReason: String, CaseIterable, Identifiable, Codable {
    case bathroom = "BATHROOM"
    case bubblers = "BUBBLERS"
    case clinic = "CLINIC"
    case itHelpDesk = "IT HELP DESK"
    case library = "LIBRARY"
    case lockers = "LOCKERS"
    case office = "OFFICE"
    case rtc = "RTC"
    case studentServices = "STDNT SVCS"
    case other = "OTHER"
    var id: String { rawValue }
}

struct BlueSlip: Identifiable, Codable {
    var id = UUID()
    // student info
    var studentName: String
    var yearLevel: String
    // reason
    var reason: BlueSlipReason
    var rtc: Bool
    var rtcNotes: String?
    // staff info
    var staffName: String
    var date: Date
    var timeSent: Date?
    var timeReturned: Date?
    var staffSignature: String?
}
