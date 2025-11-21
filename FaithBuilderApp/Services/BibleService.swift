import Foundation

enum BibleServiceError: Error {
    case invalidResponse
    case decodingError
    case invalidChapter
}

/// Response shape from bible-api.com for a passage
struct BibleAPIVerse: Decodable {
    let book_name: String?
    let chapter: Int?
    let verse: Int?
    let text: String?
}

struct BibleAPIResponse: Decodable {
    let reference: String?
    let verses: [BibleAPIVerse]
}

/// Books in standard order (we use displayName for the human reference)
enum BibleBook: Int, CaseIterable, Identifiable {
    case genesis = 1
    case exodus
    case leviticus
    case numbers
    case deuteronomy
    case joshua
    case judges
    case ruth
    case firstSamuel
    case secondSamuel
    case firstKings
    case secondKings
    case firstChronicles
    case secondChronicles
    case ezra
    case nehemiah
    case esther
    case job
    case psalms
    case proverbs
    case ecclesiastes
    case songOfSongs
    case isaiah
    case jeremiah
    case lamentations
    case ezekiel
    case daniel
    case hosea
    case joel
    case amos
    case obadiah
    case jonah
    case micah
    case nahum
    case habakkuk
    case zephaniah
    case haggai
    case zechariah
    case malachi
    case matthew
    case mark
    case luke
    case john
    case acts
    case romans
    case firstCorinthians
    case secondCorinthians
    case galatians
    case ephesians
    case philippians
    case colossians
    case firstThessalonians
    case secondThessalonians
    case firstTimothy
    case secondTimothy
    case titus
    case philemon
    case hebrews
    case james
    case firstPeter
    case secondPeter
    case firstJohn
    case secondJohn
    case thirdJohn
    case jude
    case revelation
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .genesis: return "Genesis"
        case .exodus: return "Exodus"
        case .leviticus: return "Leviticus"
        case .numbers: return "Numbers"
        case .deuteronomy: return "Deuteronomy"
        case .joshua: return "Joshua"
        case .judges: return "Judges"
        case .ruth: return "Ruth"
        case .firstSamuel: return "1 Samuel"
        case .secondSamuel: return "2 Samuel"
        case .firstKings: return "1 Kings"
        case .secondKings: return "2 Kings"
        case .firstChronicles: return "1 Chronicles"
        case .secondChronicles: return "2 Chronicles"
        case .ezra: return "Ezra"
        case .nehemiah: return "Nehemiah"
        case .esther: return "Esther"
        case .job: return "Job"
        case .psalms: return "Psalms"
        case .proverbs: return "Proverbs"
        case .ecclesiastes: return "Ecclesiastes"
        case .songOfSongs: return "Song of Songs"
        case .isaiah: return "Isaiah"
        case .jeremiah: return "Jeremiah"
        case .lamentations: return "Lamentations"
        case .ezekiel: return "Ezekiel"
        case .daniel: return "Daniel"
        case .hosea: return "Hosea"
        case .joel: return "Joel"
        case .amos: return "Amos"
        case .obadiah: return "Obadiah"
        case .jonah: return "Jonah"
        case .micah: return "Micah"
        case .nahum: return "Nahum"
        case .habakkuk: return "Habakkuk"
        case .zephaniah: return "Zephaniah"
        case .haggai: return "Haggai"
        case .zechariah: return "Zechariah"
        case .malachi: return "Malachi"
        case .matthew: return "Matthew"
        case .mark: return "Mark"
        case .luke: return "Luke"
        case .john: return "John"
        case .acts: return "Acts"
        case .romans: return "Romans"
        case .firstCorinthians: return "1 Corinthians"
        case .secondCorinthians: return "2 Corinthians"
        case .galatians: return "Galatians"
        case .ephesians: return "Ephesians"
        case .philippians: return "Philippians"
        case .colossians: return "Colossians"
        case .firstThessalonians: return "1 Thessalonians"
        case .secondThessalonians: return "2 Thessalonians"
        case .firstTimothy: return "1 Timothy"
        case .secondTimothy: return "2 Timothy"
        case .titus: return "Titus"
        case .philemon: return "Philemon"
        case .hebrews: return "Hebrews"
        case .james: return "James"
        case .firstPeter: return "1 Peter"
        case .secondPeter: return "2 Peter"
        case .firstJohn: return "1 John"
        case .secondJohn: return "2 John"
        case .thirdJohn: return "3 John"
        case .jude: return "Jude"
        case .revelation: return "Revelation"
        }
    }
}

final class BibleService {
    static let shared = BibleService()
    private init() {}
    
    /// Fetch a full KJV chapter from bible-api.com and return plain text.
    /// Uses the public-domain King James Version (KJV).
    func fetchKJVChapter(book: BibleBook, chapter: Int) async throws -> String {
        guard chapter > 0 else {
            throw BibleServiceError.invalidChapter
        }
        
        // Example reference: "John 3"
        let reference = "\(book.displayName) \(chapter)"
        let allowed = CharacterSet.urlPathAllowed
        let encodedRef = reference.addingPercentEncoding(withAllowedCharacters: allowed) ?? reference
        
        let urlString = "https://bible-api.com/\(encodedRef)?translation=kjv"
        guard let url = URL(string: urlString) else {
            throw BibleServiceError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw BibleServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result: BibleAPIResponse
        do {
            result = try decoder.decode(BibleAPIResponse.self, from: data)
        } catch {
            print("BibleService decode error: \(error)")
            throw BibleServiceError.decodingError
        }
        
        // Build a clean KJV chapter string
        let verses = result.verses
            .sorted { (a, b) in
                (a.chapter ?? 0, a.verse ?? 0) < (b.chapter ?? 0, b.verse ?? 0)
            }
        
        let lines: [String] = verses.compactMap { v in
            guard let chap = v.chapter,
                  let num = v.verse,
                  let text = v.text else { return nil }
            let bookName = v.book_name ?? book.displayName
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(bookName) \(chap):\(num)  \(cleaned)"
        }
        
        return lines.joined(separator: "\n")
    }
}
