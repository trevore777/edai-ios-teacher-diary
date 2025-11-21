import Foundation

struct StudyQuestion: Identifiable, Codable {
    var id: UUID = UUID()
    var topic: StudyTopic
    var text: String
    var answer: String?
    var createdAt: Date = Date()
    var notes: String?          // personal notes
    var category: String?       // folder / category label (e.g. "Youth", "Sermon Prep")
    
    init(
        id: UUID = UUID(),
        topic: StudyTopic,
        text: String,
        answer: String? = nil,
        createdAt: Date = Date(),
        notes: String? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.topic = topic
        self.text = text
        self.answer = answer
        self.createdAt = createdAt
        self.notes = notes
        self.category = category
    }
}
