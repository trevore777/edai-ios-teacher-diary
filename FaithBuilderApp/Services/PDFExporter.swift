#if os(iOS)

import UIKit
import SwiftUI

enum PDFExporter {
    
    static func createPDF(for question: StudyQuestion) throws -> URL {
        // A4-ish page size in points
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let cg = ctx.cgContext
            
            // Fill background white
            cg.setFillColor(UIColor.white.cgColor)
            cg.fill(pageRect)
            
            // Draw a visible border so we KNOW the PDF isn't empty
            cg.setStrokeColor(UIColor.black.cgColor)
            cg.setLineWidth(4)
            cg.stroke(pageRect.insetBy(dx: 2, dy: 2))
            
            let margin: CGFloat = 40
            var y: CGFloat = margin
            
            func drawLine(_ string: String, font: UIFont, color: UIColor = .black, leading: CGFloat = 4) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                paragraph.alignment = .left
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: paragraph,
                    .foregroundColor: color
                ]
                
                let maxWidth = pageRect.width - margin * 2
                let textRect = CGRect(x: margin, y: y, width: maxWidth, height: .greatestFiniteMagnitude)
                
                let ns = string as NSString
                let bounding = ns.boundingRect(
                    with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                )
                
                ns.draw(in: CGRect(x: margin, y: y, width: maxWidth, height: bounding.height), withAttributes: attrs)
                
                y += bounding.height + leading
            }
            
            // VERY VISIBLE HEADER
            drawLine("FAITHBUILDER STUDY", font: UIFont.boldSystemFont(ofSize: 24), color: .black, leading: 12)
            
            // Spacer
            y += 8
            
            let topicTitle = TopicMetadata.metadata(for: question.topic).title
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            
            drawLine("Topic: \(topicTitle)", font: UIFont.boldSystemFont(ofSize: 16), leading: 6)
            drawLine("Date: \(dateFormatter.string(from: question.createdAt))", font: UIFont.systemFont(ofSize: 14), leading: 6)
            
            if let category = question.category, !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawLine("Category: \(category)", font: UIFont.systemFont(ofSize: 14), leading: 10)
            } else {
                y += 10
            }
            
            // Question
            drawLine("Question:", font: UIFont.boldSystemFont(ofSize: 16), leading: 4)
            drawLine(question.text, font: UIFont.systemFont(ofSize: 14), leading: 10)
            
            // Answer
            if let answer = question.answer, !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawLine("Answer:", font: UIFont.boldSystemFont(ofSize: 16), leading: 4)
                drawLine(answer, font: UIFont.systemFont(ofSize: 14), leading: 10)
            }
            
            // Notes
            if let notes = question.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawLine("Personal Notes:", font: UIFont.boldSystemFont(ofSize: 16), leading: 4)
                drawLine(notes, font: UIFont.systemFont(ofSize: 14), leading: 6)
            }
        }
        
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Study-\(question.id.uuidString.prefix(8)).pdf")
        try data.write(to: tmpURL, options: .atomic)
        return tmpURL
    }
}

/// Simple iOS share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to update
    }
}

#endif
