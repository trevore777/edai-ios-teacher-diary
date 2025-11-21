import SwiftUI

// MARK: - Root SavedQuestionsView

struct SavedQuestionsView: View {
    @EnvironmentObject var questionStore: QuestionStore
    
    @State private var searchText: String = ""
    @State private var showingAddManualQuestion: Bool = false
    @State private var showingAIQuestionGenerator: Bool = false
    
    // Filtered by search
    private var filteredQuestions: [StudyQuestion] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return questionStore.questions
        }
        let query = trimmed.lowercased()
        
        return questionStore.questions.filter { q in
            let topicTitle = TopicMetadata.metadata(for: q.topic).title.lowercased()
            let text = q.text.lowercased()
            let answer = q.answer?.lowercased() ?? ""
            let notes = q.notes?.lowercased() ?? ""
            let category = q.category?.lowercased() ?? ""
            
            return text.contains(query)
                || answer.contains(query)
                || notes.contains(query)
                || topicTitle.contains(query)
                || category.contains(query)
        }
    }
    
    // Group into sections: category if set, otherwise topic title
    private var grouped: [(key: String, value: [StudyQuestion])] {
        let groups = Dictionary(grouping: filteredQuestions) { q -> String in
            if let cat = q.category,
               !cat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return cat.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return TopicMetadata.metadata(for: q.topic).title
            }
        }
        
        return groups
            .map { (key: $0.key, value: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
    }
    
    var body: some View {
        #if os(iOS)
        baseView
            .fullScreenCover(isPresented: $showingAddManualQuestion) {
                NavigationStack {
                    ManualQuestionEditorView()
                        .environmentObject(questionStore)
                }
            }
            .fullScreenCover(isPresented: $showingAIQuestionGenerator) {
                NavigationStack {
                    AIQuestionGeneratorView()
                        .environmentObject(questionStore)
                }
            }
        #else
        baseView
            .sheet(isPresented: $showingAddManualQuestion) {
                NavigationStack {
                    ManualQuestionEditorView()
                        .environmentObject(questionStore)
                }
            }
            .sheet(isPresented: $showingAIQuestionGenerator) {
                NavigationStack {
                    AIQuestionGeneratorView()
                        .environmentObject(questionStore)
                }
            }
        #endif
    }
    
    // Core view (used by body on both platforms)
    private var baseView: some View {
        NavigationStack {
            Group {
                if questionStore.questions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No saved questions yet")
                            .font(.headline)
                        Text("Ask a question from any topic, create one manually, or use AI to generate ideas, and they will appear here.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(grouped, id: \.key) { group in
                            Section(group.key) {
                                ForEach(group.value) { q in
                                    NavigationLink {
                                        SavedQuestionDetailView(question: q)
                                    } label: {
                                        SavedQuestionRow(question: q)
                                    }
                                }
                                .onDelete { offsets in
                                    delete(in: group.value, offsets: offsets)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Q&A")
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
                
                Button {
                    showingAddManualQuestion = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Question Manually")
                
                Button {
                    showingAIQuestionGenerator = true
                } label: {
                    Image(systemName: "sparkles")
                }
                .accessibilityLabel("Generate Questions with AI")
            }
            #else
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    showingAddManualQuestion = true
                } label: {
                    Label("Add Question", systemImage: "plus")
                }
                
                Button {
                    showingAIQuestionGenerator = true
                } label: {
                    Label("Generate Questions", systemImage: "sparkles")
                }
            }
            #endif
        }
        .searchable(text: $searchText, prompt: "Search questions, answers, notes")
    }
    
    private func delete(in sectionItems: [StudyQuestion], offsets: IndexSet) {
        let idsToDelete = offsets.map { sectionItems[$0].id }
        let all = questionStore.questions
        let indexes = all.enumerated().compactMap { index, q in
            idsToDelete.contains(q.id) ? index : nil
        }
        let indexSet = IndexSet(indexes)
        questionStore.delete(at: indexSet)
    }
}

// MARK: - Row view

private struct SavedQuestionRow: View {
    let question: StudyQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(question.text)
                    .font(.headline)
                    .lineLimit(2)
                
                if let notes = question.notes,
                   !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Spacer()
                    Image(systemName: "note.text")
                        .foregroundStyle(Color.accentColor)
                }
            }
            
            if let answer = question.answer, !answer.isEmpty {
                Text(answer)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text(TopicMetadata.metadata(for: question.topic).title)
                    .font(.caption)
                
                if let category = question.category,
                   !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(" • \(category)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                Text(dateString(question.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Detail view

struct SavedQuestionDetailView: View {
    @EnvironmentObject var questionStore: QuestionStore
    
    let question: StudyQuestion
    
    @State private var notesText: String = ""
    @State private var showSavedBanner = false
    
    #if os(iOS)
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    #endif
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(TopicMetadata.metadata(for: question.topic).title)
                        .font(.headline)
                    Text(dateString(question.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let category = question.category,
                   !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Category: \(category)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question")
                        .font(.headline)
                    Text(question.text)
                        .font(.body)
                }
                
                if let answer = question.answer, !answer.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Answer")
                            .font(.headline)
                        ScriptureLinkedText(text: answer)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Personal Notes")
                            .font(.headline)
                        Spacer()
                        if showSavedBanner {
                            Text("Saved")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("Write what God is showing you here. Notes are saved only on this device (and synced via iCloud if enabled).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $notesText)
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                }
                
                Button {
                    saveNotes()
                } label: {
                    Label("Save Notes", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                #if os(iOS)
                Button {
                    do {
                        let url = try PDFExporter.createPDF(for: question)
                        pdfURL = url
                        showShareSheet = true
                    } catch {
                        print("PDF export failed: \(error)")
                    }
                } label: {
                    Label("Export as PDF", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
                #endif
            }
            .padding()
        }
        .navigationTitle("Saved Q&A")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            notesText = question.notes ?? ""
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        #endif
    }
    
    private func saveNotes() {
        var updated = question
        let cleaned = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = cleaned.isEmpty ? nil : cleaned
        
        questionStore.update(updated)
        
        showSavedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSavedBanner = false
        }
    }
    
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Manual Question Editor

struct ManualQuestionEditorView: View {
    @EnvironmentObject var questionStore: QuestionStore
    @Environment(\.dismiss) private var dismiss
    
    private let topics = Array(StudyTopic.allCases)   // StudyTopic must be CaseIterable
    
    @State private var selectedTopicIndex: Int = 0
    @State private var questionText: String = ""
    @State private var answerText: String = ""
    @State private var categoryText: String = ""
    
    var body: some View {
        Form {
            Section("Topic") {
                Picker("Topic", selection: $selectedTopicIndex) {
                    ForEach(topics.indices, id: \.self) { idx in
                        let topic = topics[idx]
                        Text(TopicMetadata.metadata(for: topic).title)
                            .tag(idx)
                    }
                }
            }
            
            Section("Question") {
                TextField("Type the question…", text: $questionText, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            
            Section("Answer (optional)") {
                TextEditor(text: $answerText)
                    .frame(minHeight: 120)
            }
            
            Section("Category (optional)") {
                TextField("e.g. Youth Camp, Class Devotion, Sermon Prep", text: $categoryText)
            }
        }
        .navigationTitle("Add Question")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func save() {
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }
        
        let topic = topics[min(max(selectedTopicIndex, 0), topics.count - 1)]
        let trimmedAnswer = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = categoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newQ = StudyQuestion(
            topic: topic,
            text: trimmedQuestion,
            answer: trimmedAnswer.isEmpty ? nil : trimmedAnswer,
            notes: nil,
            category: trimmedCategory.isEmpty ? nil : trimmedCategory
        )
        
        questionStore.add(newQ)
        dismiss()
    }
}

// MARK: - AI Question Generator

struct AIQuestionGeneratorView: View {
    @EnvironmentObject var questionStore: QuestionStore
    @Environment(\.dismiss) private var dismiss
    
    private let topics = Array(StudyTopic.allCases)
    
    @State private var selectedTopicIndex: Int = 0
    @State private var categoryText: String = ""
    @State private var teacherPrompt: String =
    "Write 5 short, open-ended questions that help students apply this topic to their daily walk with Jesus."
    
    @State private var desiredCount: Int = 5
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section("Topic") {
                Picker("Topic", selection: $selectedTopicIndex) {
                    ForEach(topics.indices, id: \.self) { idx in
                        let topic = topics[idx]
                            Text(TopicMetadata.metadata(for: topic).title)
                            .tag(idx)
                    }
                }
            }
            
            Section("Category (optional)") {
                TextField("e.g. Youth Group, Class Devotion, Camp", text: $categoryText)
            }
            
            Section("AI Prompt") {
                TextEditor(text: $teacherPrompt)
                    .frame(minHeight: 120)
                Text("Describe the kind of questions you want. The AI will use the topic and this prompt together.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Number of Questions") {
                Stepper(value: $desiredCount, in: 1...10) {
                    Text("\(desiredCount) questions")
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("AI Question Generator")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await generateAndSave()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Generate & Save")
                    }
                }
                .disabled(isLoading)
            }
        }
    }
    
    private func generateAndSave() async {
        isLoading = true
        errorMessage = nil
        
        let topic = topics[min(max(selectedTopicIndex, 0), topics.count - 1)]
        let trimmedPrompt = teacherPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = categoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let questions = try await ChatGPTService.shared.generateStudyQuestions(
                topic: topic,
                prompt: trimmedPrompt.isEmpty ? "Write \(desiredCount) study questions for this topic." : trimmedPrompt,
                desiredCount: desiredCount
            )
            
            let categoryValue = trimmedCategory.isEmpty ? nil : trimmedCategory
            let limited = questions.prefix(desiredCount)
            
            for qText in limited {
                let cleanedQ = qText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleanedQ.isEmpty else { continue }
                
                let newQ = StudyQuestion(
                    topic: topic,
                    text: cleanedQ,
                    answer: nil,
                    notes: nil,
                    category: categoryValue
                )
                questionStore.add(newQ)
            }
            
            dismiss()
        } catch let serviceError as ChatGPTServiceError {
            errorMessage = serviceError.localizedDescription
            print("AIQuestionGeneratorView ChatGPT error: \(serviceError)")
        } catch {
            errorMessage = "Something went wrong while generating questions. Please try again."
            print("AIQuestionGeneratorView unknown error: \(error)")
        }
        
        isLoading = false
    }
}
