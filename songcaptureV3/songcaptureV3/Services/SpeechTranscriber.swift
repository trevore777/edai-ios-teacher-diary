// Services/SpeechTranscriber.swift
import Foundation
import Speech

@MainActor
final class SpeechTranscriber: NSObject, ObservableObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-AU"))

    /// Ask for Speech permission (closure API wrapped for async use).
    func requestAuth() async throws {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized { return }

        let result = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { auth in
                cont.resume(returning: auth)
            }
        }

        guard result == .authorized else {
            throw NSError(domain: "Speech", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"])
        }
    }

    /// Transcribe from a local audio file URL (closure API wrapped with continuation).
    func transcribe(url: URL) async throws -> [LyricLine] {
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Recognizer not available"])
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        let bestTranscription: SFTranscription = try await withCheckedThrowingContinuation { cont in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error { cont.resume(throwing: error); return }
                guard let result, result.isFinal else { return }
                cont.resume(returning: result.bestTranscription)
            }
            // If you want: store `task` to cancel later.
            _ = task
        }

        // Convert word segments -> lyric lines (pause-based line breaks)
        var lines: [LyricLine] = []
        var current: [LyricSegment] = []
        let segments = bestTranscription.segments
        let pauseThreshold: TimeInterval = 0.7

        for (i, seg) in segments.enumerated() {
            let text = seg.substring.trimmingCharacters(in: .whitespacesAndNewlines)
            current.append(.init(text: text, startTime: seg.timestamp))

            let isLast = i == segments.count - 1
            let nextStart = isLast ? seg.timestamp : segments[i + 1].timestamp
            let gap = nextStart - seg.timestamp

            if gap > pauseThreshold || isLast {
                lines.append(.init(segments: current))
                current.removeAll()
            }
        }
        return lines
    }
}
