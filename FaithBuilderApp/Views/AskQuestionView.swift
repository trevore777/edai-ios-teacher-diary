import SwiftUI

struct AskQuestionView: View {
    @EnvironmentObject var questionStore: QuestionStore
    
    let topic: StudyTopic
    let metadata: TopicMetadata
    
    @State private var questionText: String = ""
    @State private var answerText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // Bible context
    @State private var selectedBook: BibleBook = .john
    @State private var chapterInput: String = "3"
    @State private var isLoadingBible: Bool = false
    @State private var bibleText: String = ""
    @State private var bibleError: String?
    
    // Category / folder
    @State private var categoryText: String = ""
    
    // Text-to-speech
    @StateObject private var speechManager = SpeechManager()
    
    @FocusState private var isQuestionFocused: Bool
    
    // MARK: - Parsed answer (main text + suggested next question)
    
    /// Splits the answer into:
    /// - mainText: everything except the line that starts with "Next question you could ask:"
    /// - nextQuestion: the text after that prefix, if present
    private var parsedAnswer: (mainText: String, nextQuestion: String?) {
        guard !answerText.isEmpty else {
            return ("", nil)
        }
        
        let prefix = "Next question you could ask:"
        let lines = answerText.components(separatedBy: .newlines)
        
        var filteredLines: [String] = []
        var suggestion: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix(prefix) {
                let remainder = trimmed
                    .replacingOccurrences(of: prefix, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainder.isEmpty {
                    suggestion = remainder
                }
            } else {
                filteredLines.append(line)
            }
        }
        
        let main = filteredLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (main, suggestion)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Topic header
                    Text("Ask about:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(metadata.title)
                        .font(.title2.bold())
                    
                    // Suggested prompts from TopicMetadata
                    if !metadata.starterQuestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tap a suggested question or write your own:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ForEach(metadata.starterQuestions, id: \.self) { prompt in
                                Button {
                                    questionText = prompt
                                    isQuestionFocused = true
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb")
                                            .foregroundStyle(Color.accentColor)
                                        Text(prompt)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    // Question input
                    TextField("Type your question here…", text: $questionText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)
                        .focused($isQuestionFocused)
                    
                    // Category / folder label
                    TextField("Category (optional, e.g. Youth Camp, Devotions)", text: $categoryText)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Praying, thinking, and searching the Scriptures…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    // Answer
                    if !answerText.isEmpty {
                        let parsed = parsedAnswer
                        
                        Divider()
                        HStack {
                            Text("Response")
                                .font(.headline)
                            Spacer()
                            Button {
                                // For speech we keep using the full answer (including next-question line)
                                speechManager.toggleSpeaking(text: answerText)
                            } label: {
                                Label(
                                    speechManager.isSpeaking ? "Stop" : "Read Aloud",
                                    systemImage: speechManager.isSpeaking ? "stop.fill" : "speaker.wave.2.fill"
                                )
                                .font(.caption)
                            }
                        }
                        
                        if !parsed.mainText.isEmpty {
                            ScriptureLinkedText(text: parsed.mainText)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                        
                        // Suggested next question as a button
                        if let nextQ = parsed.nextQuestion {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Keep going:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Button {
                                    questionText = nextQ
                                    // Optional: keep the previous answer visible
                                    // or clear it if you want a “fresh” screen.
                                    // answerText = ""
                                    errorMessage = nil
                                    DispatchQueue.main.async {
                                        isQuestionFocused = true
                                    }
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "arrow.turn.down.right")
                                            .foregroundStyle(Color.accentColor)
                                        Text(nextQ)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.accentColor.opacity(0.8))
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    // MARK: - KJV Bible context
                    
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Read KJV Scripture for context")
                            .font(.headline)
                        
                        Text("Choose a book and chapter to read in the King James Version (KJV) for study context.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Picker("Book", selection: $selectedBook) {
                                ForEach(BibleBook.allCases) { book in
                                    Text(book.displayName).tag(book)
                                }
                            }
                            #if os(iOS)
                            .pickerStyle(.menu)
                            #endif
                            
                            TextField("Chapter", text: $chapterInput)
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                        }
                        
                        HStack(spacing: 8) {
                            Button {
                                Task {
                                    await fetchBibleChapter()
                                }
                            } label: {
                                if isLoadingBible {
                                    HStack {
                                        ProgressView()
                                        Text("Loading…")
                                    }
                                } else {
                                    Label("Show Chapter", systemImage: "book.pages")
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            if !bibleText.isEmpty {
                                Button {
                                    speechManager.toggleSpeaking(text: bibleText)
                                } label: {
                                    Label(
                                        speechManager.isSpeaking ? "Stop" : "Read Chapter Aloud",
                                        systemImage: speechManager.isSpeaking ? "stop.fill" : "speaker.wave.2.fill"
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if let chapter = Int(chapterInput),
                               let url = BibleLinkBuilder.chapterURL(book: selectedBook, chapter: chapter) {
                                Link(destination: url) {
                                    Label("Open Online", systemImage: "safari")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        if let bError = bibleError {
                            Text(bError)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if !bibleText.isEmpty {
                            ScrollView {
                                Text(bibleText)
                                    .font(.callout)
                                    .textSelection(.enabled)
                                    .padding(.top, 4)
                            }
                            .frame(minHeight: 120, maxHeight: 260)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.3))
                            )
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding()
            }
            
            Divider()
            
            // Bottom bar
            HStack {
                Button("Clear") {
                    questionText = ""
                    answerText = ""
                    errorMessage = nil
                    bibleText = ""
                    bibleError = nil
                    categoryText = ""
                    speechManager.stop()
                }
                .disabled(questionText.isEmpty && answerText.isEmpty && bibleText.isEmpty)
                
                Spacer()
                
                Button {
                    Task {
                        await submitQuestion()
                    }
                } label: {
                    Label("Ask", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding([.horizontal, .bottom])
        }
        .navigationTitle("Ask a Question")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            #if os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isQuestionFocused = true
            }
            #endif
        }
    }
    
    // MARK: - Actions
    
    private func submitQuestion() async {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let answer = try await ChatGPTService.shared.answerQuestion(
                topic: topic,
                question: trimmed
            )
            answerText = answer
            
            let cleanedCategory = categoryText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let saved = StudyQuestion(
                topic: topic,
                text: trimmed,
                answer: answer,
                notes: nil,
                category: cleanedCategory.isEmpty ? nil : cleanedCategory
            )
            await MainActor.run {
                questionStore.add(saved)
            }
        } catch let serviceError as ChatGPTServiceError {
            errorMessage = serviceError.localizedDescription
            print("AskQuestionView ChatGPT error: \(serviceError)")
        } catch {
            errorMessage = "Something went wrong while getting an answer. Please try again later."
            print("AskQuestionView unknown error: \(error)")
        }
        
        isLoading = false
    }
    
    private func fetchBibleChapter() async {
        bibleError = nil
        bibleText = ""
        
        guard let chapter = Int(chapterInput), chapter > 0 else {
            bibleError = "Please enter a valid chapter number."
            return
        }
        
        isLoadingBible = true
        do {
            let text = try await BibleService.shared.fetchKJVChapter(
                book: selectedBook,
                chapter: chapter
            )
            await MainActor.run {
                bibleText = text
            }
        } catch {
            await MainActor.run {
                bibleError = "Could not load that chapter. Please check your internet connection or try another chapter."
            }
            print("Bible fetch error: \(error)")
        }
        isLoadingBible = false
    }
}
