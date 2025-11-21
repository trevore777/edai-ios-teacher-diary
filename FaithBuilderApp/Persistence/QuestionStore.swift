import Foundation
import Combine

final class QuestionStore: ObservableObject {
    @Published private(set) var questions: [StudyQuestion] = []
    
    private let storeKey = "SavedQuestionsJSON"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        load()
        
        // Auto-save whenever questions change
        $questions
            .dropFirst()
            .debounce(for: .seconds(0.8), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
        
        // Listen for iCloud KV changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUbiquitousChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        
        // Ask iCloud for latest
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    // MARK: - Public API
    
    func add(_ question: StudyQuestion) {
        questions.insert(question, at: 0)
    }
    
    func update(_ question: StudyQuestion) {
        if let index = questions.firstIndex(where: { $0.id == question.id }) {
            questions[index] = question
        }
    }
    
    func delete(at offsets: IndexSet) {
        questions.remove(atOffsets: offsets)
    }
    
    // MARK: - Persistence (iCloud Key-Value)
    
    private func load() {
        let store = NSUbiquitousKeyValueStore.default
        guard let data = store.data(forKey: storeKey) else {
            questions = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([StudyQuestion].self, from: data)
            questions = decoded
        } catch {
            print("QuestionStore: Failed to decode questions from iCloud: \(error)")
            questions = []
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(questions)
            let store = NSUbiquitousKeyValueStore.default
            store.set(data, forKey: storeKey)
            store.synchronize()
        } catch {
            print("QuestionStore: Failed to encode questions for iCloud: \(error)")
        }
    }
    
    @objc private func handleUbiquitousChange(_ notification: Notification) {
        // When iCloud updates from another device, reload
        load()
    }
}
