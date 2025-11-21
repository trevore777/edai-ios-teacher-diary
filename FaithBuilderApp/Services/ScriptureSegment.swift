import Foundation
import SwiftUI

struct ScriptureSegment {
    let text: String
    let reference: String?   // if non-nil, this segment is a Scripture ref
}

enum ScriptureTextParser {
    
    /// Build an AttributedString where Bible references like "John 3:16"
    /// are tagged as links to an online KJV Bible.
    static func attributedText(for text: String) -> AttributedString {
        // Regex for references like "John 3:16", "1 Peter 2:9-10"
        let pattern = #"\b(?:[1-3]\s*)?(?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+\d+:\d+(?:-\d+)?\b"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return AttributedString(text)
        }
        
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        
        // Start with a mutable Foundation attributed string
        let attributed = NSMutableAttributedString(string: text)
        
        let matches = regex.matches(in: text, options: [], range: fullRange)
        for match in matches {
            let range = match.range
            let refText = nsText.substring(with: range)
            
            if let url = BibleLinkBuilder.url(forReference: refText) {
                // Mark this range as a link
                attributed.addAttribute(.link, value: url, range: range)
            }
        }
        
        // Convert to SwiftUI-compatible AttributedString
        if let converted = try? AttributedString(attributed, including: \.foundation) {
            return converted
        } else {
            return AttributedString(text)
        }
    }
}

/// SwiftUI view: a single wrapping Text with clickable Scripture links.
struct ScriptureLinkedText: View {
    let text: String
    
    var body: some View {
        let attributed = ScriptureTextParser.attributedText(for: text)
        Text(attributed)
    }
}
