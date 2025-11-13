import Foundation
import Speech

@MainActor
final class SpeechTranscriber: ObservableObject {
    @Published var transcript: String = ""
    @Published var isTranscribing: Bool = false
    @Published var lastError: String? = nil
    
    enum STError: LocalizedError {
        case notAuthorized
        case recognizerUnavailable
        case fileMissing
        var errorDescription: String? {
            switch self {
            case .notAuthorized: return "Speech recognition is not authorized. Enable it in Settings > Privacy & Security > Speech Recognition."
            case .recognizerUnavailable: return "Speech recognizer is currently unavailable. Try again shortly."
            case .fileMissing: return "Audio file could not be found or opened."
            }
        }
    }
    
    func ensureAuthorization() async throws {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized { return }
        if status == .notDetermined {
            let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                SFSpeechRecognizer.requestAuthorization { s in
                    cont.resume(returning: s == .authorized)
                }
            }
            if granted { return }
        }
        throw STError.notAuthorized
    }
    
    func transcribeFile(url: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw STError.fileMissing
        }
        try await ensureAuthorization()
        
        let attempts: [(Locale, Bool)] = [
            (Locale(identifier: "en-AU"), true),   // on-device AU
            (Locale(identifier: "en-AU"), false),  // server AU
            (Locale(identifier: "en-US"), false)   // server US
        ]
        
        var lastErr: Error?
        for (loc, onDev) in attempts {
            do {
                let text = try await recognize(url: url, locale: loc, onDevice: onDev)
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return text }
                lastErr = NSError(domain: "Speech", code: -10,
                                  userInfo: [NSLocalizedDescriptionKey: "Empty transcript for \(loc.identifier) onDevice=\(onDev)"])
            } catch {
                lastErr = error
            }
        }
        throw lastErr ?? NSError(domain: "Speech", code: -1, userInfo: [NSLocalizedDescriptionKey: "All recognition attempts failed"])
    }
    
    private func recognize(url: URL, locale: Locale, onDevice: Bool) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw STError.recognizerUnavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = onDevice
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        
        isTranscribing = true
        lastError = nil
        
        var best = ""
        let text: String = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error = error { cont.resume(throwing: error); return }
                if let result = result {
                    best = result.bestTranscription.formattedString
                    if result.isFinal { cont.resume(returning: best) }
                }
            }
            // Safety timeout: if no final after 15s, return best partial if present
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                if !best.isEmpty { cont.resume(returning: best) }
            }
            _ = task
        }
        
        self.transcript = text
        self.isTranscribing = false
        return text
    }
}
