import Foundation

struct ChatGPTMessage: Encodable {
    let role: String
    let content: String
}

struct ChatGPTRequestBody: Encodable {
    let model: String
    let messages: [ChatGPTMessage]
    let temperature: Double
    let max_tokens: Int
}

struct ChatGPTChoiceMessage: Decodable {
    let role: String
    let content: String
}

struct ChatGPTChoice: Decodable {
    let index: Int
    let message: ChatGPTChoiceMessage
}

struct ChatGPTErrorBody: Decodable {
    struct OpenAIError: Decodable {
        let message: String
        let type: String?
    }
    let error: OpenAIError
}

struct ChatGPTResponseBody: Decodable {
    let choices: [ChatGPTChoice]
}

enum ChatGPTServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse(status: Int, message: String?)
    case noChoices
    case network(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No OpenAI API key has been configured."
        case .invalidResponse(let status, let message):
            if let message = message {
                return "Server error (\(status)): \(message)"
            } else {
                return "Server error (\(status))."
            }
        case .noChoices:
            return "The AI did not return any choices."
        case .network(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

final class ChatGPTService {
    static let shared = ChatGPTService()
    private init() {}
    
    // MARK: - Q&A for a single question
    
    func answerQuestion(
        topic: StudyTopic,
        question: String
    ) async throws -> String {
        
        let key = ApiKeys.openAI.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.hasPrefix("YOUR_") else {
            throw ChatGPTServiceError.missingAPIKey
        }
        
        let modelName = "gpt-4.1-mini"   // or "gpt-4o-mini" depending on your account
        
        let topicMeta = TopicMetadata.metadata(for: topic)
        let systemText = buildSystemPrompt(for: topic, metadata: topicMeta)
        
        let messages = [
            ChatGPTMessage(role: "system", content: systemText),
            ChatGPTMessage(role: "user", content: question)
        ]
        
        let body = ChatGPTRequestBody(
            model: modelName,
            messages: messages,
            temperature: 0.4,
            max_tokens: 900
        )
        
        let (data, http) = try await sendRequest(body: body, apiKey: key)
        let result = try decodeResponse(data: data, http: http)
        
        guard let first = result.choices.first else {
            throw ChatGPTServiceError.noChoices
        }
        
        return first.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Generate multiple study questions (no answers)
    
    func generateStudyQuestions(
        topic: StudyTopic,
        prompt: String,
        desiredCount: Int
    ) async throws -> [String] {
        
        let key = ApiKeys.openAI.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.hasPrefix("YOUR_") else {
            throw ChatGPTServiceError.missingAPIKey
        }
        
        let modelName = "gpt-4.1-mini"
        let topicMeta = TopicMetadata.metadata(for: topic)
        let systemText = buildQuestionGeneratorPrompt(for: topic, metadata: topicMeta, desiredCount: desiredCount)
        
        let userPrompt = """
        \(prompt)

        Please ONLY return a list of \(desiredCount) numbered questions, one per line, with no answers and no extra explanation.
        """
        
        let messages = [
            ChatGPTMessage(role: "system", content: systemText),
            ChatGPTMessage(role: "user", content: userPrompt)
        ]
        
        let body = ChatGPTRequestBody(
            model: modelName,
            messages: messages,
            temperature: 0.7,
            max_tokens: 800
        )
        
        let (data, http) = try await sendRequest(body: body, apiKey: key)
        let result = try decodeResponse(data: data, http: http)
        
        guard let first = result.choices.first else {
            throw ChatGPTServiceError.noChoices
        }
        
        let raw = first.message.content
        let questions = parseQuestions(from: raw)
        
        if questions.isEmpty {
            return [raw.trimmingCharacters(in: .whitespacesAndNewlines)]
        } else {
            return questions
        }
    }
    
    // MARK: - Shared HTTP helpers
    
    private func sendRequest(body: ChatGPTRequestBody, apiKey: String) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ChatGPTServiceError.invalidResponse(status: -1, message: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 30
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("ChatGPTService network error: \(error)")
            throw ChatGPTServiceError.network(error)
        }
        
        guard let http = response as? HTTPURLResponse else {
            throw ChatGPTServiceError.invalidResponse(status: -1, message: "No HTTPURLResponse")
        }
        
        return (data, http)
    }
    
    private func decodeResponse(data: Data, http: HTTPURLResponse) throws -> ChatGPTResponseBody {
        guard 200..<300 ~= http.statusCode else {
            var serverMessage: String? = nil
            if let errorBody = try? JSONDecoder().decode(ChatGPTErrorBody.self, from: data) {
                serverMessage = errorBody.error.message
            } else if let raw = String(data: data, encoding: .utf8) {
                serverMessage = raw
            }
            print("ChatGPTService HTTP \(http.statusCode): \(serverMessage ?? "No error message")")
            throw ChatGPTServiceError.invalidResponse(status: http.statusCode, message: serverMessage)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ChatGPTResponseBody.self, from: data)
    }
    
    // MARK: - Prompts
    
    private func buildSystemPrompt(for topic: StudyTopic, metadata: TopicMetadata) -> String {
        """
        \(SearchForTruthContext.baseContext)

        Current topic: \(metadata.title)
        Short topic description: \(metadata.description)

        Topic-specific guidance:
        \(SearchForTruthContext.topicHint(for: topic))

        Additional instructions:

        - Always answer as a gentle Bible study tutor.
        - Use Scripture references often, but do not overload the answer with too many verses.
        - Keep answers 2–6 short paragraphs unless the question clearly needs more.
        - Avoid attacking other denominations. Teach positively from Scripture.
        - If a question sounds like it involves self-harm, abuse, trauma, or serious mental health issues,
          say kindly that you cannot handle that and that the student should talk to a trusted adult,
          school chaplain, counsellor, pastor, or parent/guardian.
        - This app is for a Christian school environment. Keep your tone respectful, hopeful, and age-appropriate.
        """
    }
    
    private func buildQuestionGeneratorPrompt(
        for topic: StudyTopic,
        metadata: TopicMetadata,
        desiredCount: Int
    ) -> String {
        """
        \(SearchForTruthContext.baseContext)

        You are helping a Christian teacher prepare Bible study questions for students.

        Current topic: \(metadata.title)
        Short topic description: \(metadata.description)

        Task: Generate \(desiredCount) short, open-ended questions that:
        - Help students think more deeply about this topic
        - Encourage them to apply Scripture and follow Jesus more closely
        - Are suitable for a Christian school environment
        - Do NOT include full answers, only the questions themselves
        """
    }
    
    // MARK: - Simple parser for numbered/bulleted lists
    
    private func parseQuestions(from text: String) -> [String] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var result: [String] = []
        
        for line in lines {
            var cleaned = line
            
            // Remove leading "1. ", "2) " etc.
            cleaned = cleaned.replacingOccurrences(
                of: #"^[0-9]+[.)]\s*"#,
                with: "",
                options: .regularExpression
            )
            
            // Remove leading "- " or "• "
            cleaned = cleaned.replacingOccurrences(
                of: #"^[-•]\s*"#,
                with: "",
                options: .regularExpression
            )
            
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                result.append(cleaned)
            }
        }
        
        return result
    }
}
