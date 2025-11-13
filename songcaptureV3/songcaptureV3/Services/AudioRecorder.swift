// Services/AudioRecorder.swift
import Foundation
import AVFoundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func startRecording(filename: String = UUID().uuidString + ".m4a") throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.record()
        isRecording = true
        currentTime = 0

        // Use selector-based timer to avoid @Sendable closure issues in Swift 6
        timer?.invalidate()
        let t = Timer(timeInterval: 0.05, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t

        return url
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil
    }

    @objc private func handleTimer() {
        guard let rec = recorder else { return }
        rec.updateMeters()
        currentTime = rec.currentTime
    }
}
