//
//  BibleAPI.swift
//  TeacherDiary
//
//  Created by Trevor Elliott on 10/11/2025.
//


import Foundation

// MARK: - Bible API (KJV Verse of the Day)
final class BibleAPI {
    struct BibleAPIVerse: Decodable {
        let reference: String
        let verses: [Verse]
        struct Verse: Decodable { let text: String }
    }

    struct OurMannaVOTD: Decodable {
        let verse: VerseObj
        struct VerseObj: Decodable {
            let details: Details
            struct Details: Decodable { let reference: String }
            let text: String
        }
    }

    /// Fetch a specific reference in KJV (e.g., "John 3:16")
    func fetchVerse(reference: String) async throws -> (text: String, ref: String) {
        let q = reference.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? reference
        let url = URL(string: "https://bible-api.com/\(q)?translation=kjv")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(BibleAPIVerse.self, from: data)
        let text = decoded.verses.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.joined()
        return (text, decoded.reference)
    }

    /// Verse of the day: OurManna API → then fetch KJV text
    func fetchVerseOfTheDay() async throws -> (text: String, ref: String) {
        let votdURL = URL(string: "https://beta.ourmanna.com/api/v1/get/?format=json")!
        let (data, _) = try await URLSession.shared.data(from: votdURL)
        let votd = try JSONDecoder().decode(OurMannaVOTD.self, from: data)
        let ref = votd.verse.details.reference
        do {
            return try await fetchVerse(reference: ref)
        } catch {
            // fallback to OurManna text
            return (votd.verse.text, ref)
        }
    }
}
