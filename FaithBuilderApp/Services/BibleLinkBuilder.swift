//
//  BibleLinkBuilder.swift
//  FaithBuilderApp
//
//  Created by Trevor Elliott on 20/11/2025.
//


import Foundation

enum BibleLinkBuilder {
    
    /// Builds a URL to an online KJV Bible passage for a simple reference like "John 3:16".
    static func url(forReference reference: String) -> URL? {
        let base = "https://www.biblegateway.com/passage/?search="
        
        // Basic cleaning & encoding
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Replace spaces with '+' for a simple query
        let query = trimmed.replacingOccurrences(of: " ", with: "+")
        let urlString = "\(base)\(query)&version=KJV"
        return URL(string: urlString)
    }
    
    /// Builds a URL to an online KJV Bible chapter from the selected book + chapter.
    static func chapterURL(book: BibleBook, chapter: Int) -> URL? {
        guard chapter > 0 else { return nil }
        let ref = "\(book.displayName) \(chapter)"
        return url(forReference: ref)
    }
}
