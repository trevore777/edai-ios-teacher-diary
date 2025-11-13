import Foundation
import AVFoundation

enum AudioConvertError: Error { case cannotOpen, cannotCreateOut, convertFailed }

/// Convert any source (m4a/mp3/aiff/wav) to 16 kHz, mono, 16-bit PCM WAV.
func makePCM16MonoWAV(from sourceURL: URL) throws -> URL {
    // 1) Open input
    guard let inFile = try? AVAudioFile(forReading: sourceURL) else {
        throw AudioConvertError.cannotOpen
    }

    // 2) Target linear PCM @ 16 kHz mono, 16-bit
    let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                     sampleRate: 16_000,
                                     channels: 1,
                                     interleaved: true)!
    // Explicit WAV/PCM keys
    var wavSettings: [String : Any] = targetFormat.settings
    wavSettings[AVFormatIDKey] = kAudioFormatLinearPCM
    wavSettings[AVLinearPCMIsBigEndianKey] = false
    wavSettings[AVLinearPCMIsFloatKey] = false
    wavSettings[AVLinearPCMBitDepthKey] = 16
    wavSettings[AVSampleRateKey] = 16_000
    wavSettings[AVNumberOfChannelsKey] = 1

    // 3) Output URL with .wav extension
    let outURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("wav")

    // 4) Create output file WITHOUT using fileType: (works across SDKs)
    let outFile: AVAudioFile
    do {
        outFile = try AVAudioFile(
            forWriting: outURL,
            settings: wavSettings,
            commonFormat: .pcmFormatInt16,   // ✅ use this initializer
            interleaved: true
        )
    } catch {
        throw AudioConvertError.cannotCreateOut
    }

    // 5) Converter
    guard let converter = AVAudioConverter(from: inFile.processingFormat, to: targetFormat) else {
        throw AudioConvertError.convertFailed
    }

    // 6) Chunked convert/write
    let inFormat = inFile.processingFormat
    let chunk: AVAudioFrameCount = 4096

    while true {
        guard let inBuf = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: chunk) else {
            throw AudioConvertError.convertFailed
        }
        try inFile.read(into: inBuf, frameCount: chunk)
        if inBuf.frameLength == 0 { break } // EOF

        guard let outBuf = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                            frameCapacity: AVAudioFrameCount(targetFormat.sampleRate)) else {
            throw AudioConvertError.convertFailed
        }

        var err: NSError?
        let status = converter.convert(to: outBuf, error: &err) { _, outStatus in
            if inBuf.frameLength == 0 {
                outStatus.pointee = .endOfStream
                return nil
            } else {
                outStatus.pointee = .haveData
                return inBuf
            }
        }

        switch status {
        case .haveData:
            try outFile.write(from: outBuf)
        case .endOfStream:
            break
        case .error:
            throw err ?? AudioConvertError.convertFailed
        @unknown default:
            throw AudioConvertError.convertFailed
        }
    }

    return outURL
}
