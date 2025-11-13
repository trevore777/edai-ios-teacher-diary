import Foundation
import AVFoundation
import Combine

final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0
    @Published var lastFileURL: URL?

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?

    func startRecording() throws -> URL {
        // Permissions
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: break
            case .denied:
                throw NSError(domain: "Audio", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
            case .undetermined:
                let sema = DispatchSemaphore(value: 0)
                var allowed = false
                AVAudioApplication.requestRecordPermission { ok in
                    allowed = ok; sema.signal()
                }
                sema.wait()
                guard allowed else {
                    throw NSError(domain: "Audio", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Microphone permission not granted"])
                }
            @unknown default: break
            }
        } else {
            let sess = AVAudioSession.sharedInstance()
            var ok = (sess.recordPermission == .granted)
            if sess.recordPermission == .undetermined {
                let sema = DispatchSemaphore(value: 0)
                sess.requestRecordPermission { allowed in ok = allowed; sema.signal() }
                sema.wait()
            }
            guard ok else {
                throw NSError(domain: "Audio", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Microphone permission not granted"])
            }
        }

        // Session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        // File
        let url = Self.newRecordingURL()
        lastFileURL = url

        // Settings
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Start
        let rec = try AVAudioRecorder(url: url, settings: settings)
        rec.delegate = self
        rec.isMeteringEnabled = true
        guard rec.record() else {
            throw NSError(domain: "Audio", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"])
        }
        recorder = rec

        DispatchQueue.main.async { self.isRecording = true }
        startMetering()
        return url
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        stopMetering()
        DispatchQueue.main.async { self.isRecording = false }
    }

    // Metering via selector (Swift 6 sendable-safe)
    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(timeInterval: 0.05,
                                          target: self,
                                          selector: #selector(meterTick),
                                          userInfo: nil,
                                          repeats: true)
        RunLoop.main.add(meterTimer!, forMode: .common)
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    @objc private func meterTick() {
        guard let r = recorder, r.isRecording else { return }
        r.updateMeters()
        currentTime = r.currentTime
    }

    private static func newRecordingURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        return dir.appendingPathComponent("capture-\(stamp).m4a")
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Recorder encode error:", error?.localizedDescription ?? "unknown")
    }
}
