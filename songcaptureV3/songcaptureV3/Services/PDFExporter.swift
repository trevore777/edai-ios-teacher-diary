// Services/PDFExporter.swift
import Foundation
import UIKit

struct PDFExporter {
    /// Renders a simple chord-over-lyrics PDF and returns its file URL in Documents.
    static func export(song: Song, aligned: [[AlignedLine]]) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 points
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let margin: CGFloat = 28
            let titleFont = UIFont.boldSystemFont(ofSize: 22)
            let infoFont  = UIFont.systemFont(ofSize: 12)
            let mono      = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            let body      = UIFont.systemFont(ofSize: 14)
            
            // Title
            (song.title as NSString).draw(
                at: CGPoint(x: margin, y: margin),
                withAttributes: [.font: titleFont]
            )
            
            // Key / Capo info
            let info = "Key: \(song.key.rawValue)   Capo (play in G): \(Transposer.capoForG(songKey: song.key))"
            (info as NSString).draw(
                at: CGPoint(x: margin, y: margin + 26),
                withAttributes: [.font: infoFont]
            )
            
            // Body (chords above, lyrics below)
            // Inside PDFExporter.export(...) after info text:
            var y = margin + 60
            let chordFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
            let lyricFont = UIFont.systemFont(ofSize: 14)
            
            for line in aligned {
                var x = margin
                
                for w in line {
                    // Draw chord (small, lifted)
                    if let chord = w.chordAbove, !chord.trimmingCharacters(in: .whitespaces).isEmpty {
                        let chordStr = chord as NSString
                        let chordSize = chordStr.size(withAttributes: [.font: chordFont])
                        chordStr.draw(at: CGPoint(x: x, y: y - 8), // slightly above baseline
                                      withAttributes: [.font: chordFont,
                                                       .foregroundColor: UIColor.secondaryLabel])
                        x += chordSize.width + 2
                    } else {
                        x += 2
                    }
                    
                    // Draw the word
                    let word = (w.text as NSString)
                    let wordSize = word.size(withAttributes: [.font: lyricFont])
                    word.draw(at: CGPoint(x: x, y: y),
                              withAttributes: [.font: lyricFont, .foregroundColor: UIColor.label])
                    x += wordSize.width + 8
                    
                    // Simple wrap if near right margin
                    if x > pageRect.width - margin - 40 {
                        y += 24
                        x = margin
                    }
                }
                
                y += 28 // line spacing
                
                // page break
                if y > pageRect.height - margin - 40 {
                    ctx.beginPage()
                    y = margin
                }
            }
        }

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(sanitize(song.title)).pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            print("PDF write error:", error)
            return nil
        }
    }

    private static func sanitize(_ s: String) -> String {
        s.replacingOccurrences(of: "[/\\\\:*?\"<>|]", with: "_", options: .regularExpression)
    }
}
