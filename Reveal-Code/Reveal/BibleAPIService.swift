//
//  BibleAPIService.swift
//  Reveal
//
//  Reads full chapters from bible.helloao.org, the API that actually works
//  (see Data/BIBLE_API_GUIDE.md — the endpoint documented there 404s).
//
//  Shape of the real API (verified against the live service):
//
//    GET https://bible.helloao.org/api/eng_web/JHN/3.json
//    GET https://bible.helloao.org/api/cmn_cu1/JHN/3.json
//
//    { "translation": {...},
//      "book":   { "id": "JHN", "name": "John", ... },
//      "chapter": { "number": 3,
//                   "content": [ { "type": "heading", "content": ["..."] },
//                                { "type": "verse", "number": 1,
//                                  "content": [ "text" | {"text": "...", "poem": 1} ] } ] } }
//
//  No API key, no Info.plist entry, no ATS exception: plain HTTPS GETs.
//  Translation ids: eng_web (World English Bible) / cmn_cu1 (新标点和合本).
//

import Foundation

// MARK: - Models

/// One verse of a chapter, with the section heading that precedes it (if any).
struct BibleVerse: Identifiable, Hashable {
    let number: Int
    let heading: String?
    let text: String

    var id: Int { number }
}

/// A fetched chapter, ready to render.
struct BibleChapter: Hashable {
    let bookName: String        // localised book name as the API reports it
    let bookCode: String        // USFM, e.g. "LEV"
    let chapterNumber: Int
    let verses: [BibleVerse]

    func verse(_ number: Int) -> BibleVerse? {
        verses.first { $0.number == number }
    }
}

// MARK: - Service

/// Fetches whole chapters, caches them in memory, and lets URLCache keep a
/// disk copy so a re-opened passage renders without a round trip.
actor BibleAPIService {
    static let shared = BibleAPIService()

    enum Translation: String, Sendable {
        case web = "eng_web"    // World English Bible
        case cuv = "cmn_cu1"    // 新标点和合本
    }

    enum APIError: LocalizedError {
        case unknownBook(String)
        case http(Int)
        case empty
        case malformed

        var errorDescription: String? {
            switch self {
            case .unknownBook(let book): return "No book code for “\(book)”"
            case .http(let code):        return "Server returned HTTP \(code)"
            case .empty:                 return "The chapter came back empty"
            case .malformed:             return "Could not read the response"
            }
        }
    }

    private struct Key: Hashable {
        let translation: Translation
        let usfm: String
        let chapter: Int
    }

    private var cache: [Key: BibleChapter] = [:]
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 20
        // Chapter text never changes; serve it from disk when we have it.
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 4 * 1024 * 1024,
            diskCapacity: 32 * 1024 * 1024,
            diskPath: "BibleAPICache"
        )
        session = URLSession(configuration: config)
    }

    // MARK: Public

    static func translation(for language: String) -> Translation {
        language == "zh-Hans" ? .cuv : .web
    }

    /// Book name as used by the bundled cards ("Psalm", "1 Corinthians") → USFM.
    static func usfmCode(for book: String) -> String? {
        if let direct = bookCodes[book] { return direct }
        if book == "Psalm" { return "PSA" }          // cards use the singular
        if book == "Song of Songs" { return "SNG" }
        return nil
    }

    /// Fetches (or returns a cached) whole chapter.
    func chapter(book: String, chapter number: Int, language: String) async throws -> BibleChapter {
        let translation = Self.translation(for: language)
        guard let usfm = Self.usfmCode(for: book) else { throw APIError.unknownBook(book) }

        let key = Key(translation: translation, usfm: usfm, chapter: number)
        if let cached = cache[key] { return cached }

        guard let url = URL(string: "https://bible.helloao.org/api/\(translation.rawValue)/\(usfm)/\(number).json") else {
            throw APIError.unknownBook(book)
        }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.http(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ChapterResponse.self, from: data)
        let verses = Self.flatten(decoded.chapter.content)
        guard !verses.isEmpty else { throw APIError.empty }

        let result = BibleChapter(
            bookName: decoded.book?.name ?? book,
            bookCode: usfm,
            chapterNumber: decoded.chapter.number,
            verses: verses
        )
        cache[key] = result
        return result
    }

    /// Decodes one chapter payload. Split out of `chapter(book:chapter:language:)`
    /// so it can be exercised against fixture data without a network call.
    static func parse(_ data: Data, fallbackBookName: String, usfm: String) throws -> BibleChapter {
        let decoded = try JSONDecoder().decode(ChapterResponse.self, from: data)
        let verses = flatten(decoded.chapter.content)
        guard !verses.isEmpty else { throw APIError.empty }
        return BibleChapter(
            bookName: decoded.book?.name ?? fallbackBookName,
            bookCode: usfm,
            chapterNumber: decoded.chapter.number,
            verses: verses
        )
    }

    func clearCache() {
        cache.removeAll()
        session.configuration.urlCache?.removeAllCachedResponses()
    }

    // MARK: Parsing

    /// The API groups text into typed blocks. Verses carry a number; headings
    /// and Hebrew sub-titles ("ALEPH") are separate blocks that belong to the
    /// verse that follows them; `line` blocks continue the previous verse.
    private static func flatten(_ blocks: [Block]) -> [BibleVerse] {
        var verses: [BibleVerse] = []
        var pendingHeading: String?

        for block in blocks {
            let text = clean(block.content?.map(\.text).joined(separator: " ") ?? "")
            switch block.type {
            case "verse":
                guard let number = block.number else { continue }
                if var last = verses.last, last.number == number {
                    // A verse split across blocks — append.
                    last = BibleVerse(number: last.number, heading: last.heading, text: clean(last.text + " " + text))
                    verses[verses.count - 1] = last
                } else {
                    verses.append(BibleVerse(number: number, heading: pendingHeading, text: text))
                }
                pendingHeading = nil
            case "line":
                guard var last = verses.popLast() else {
                    pendingHeading = text
                    continue
                }
                last = BibleVerse(number: last.number, heading: last.heading, text: clean(last.text + " " + text))
                verses.append(last)
            default:
                // heading / hebrew_subtitle / subtitle / anything else textual
                if !text.isEmpty { pendingHeading = text }
            }
        }
        return verses
    }

    private static func clean(_ raw: String) -> String {
        raw.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Wire types

    private struct ChapterResponse: Decodable {
        struct Book: Decodable {
            let id: String
            let name: String
        }
        struct Chapter: Decodable {
            let number: Int
            let content: [Block]
        }
        let book: Book?
        let chapter: Chapter
    }

    private struct Block: Decodable {
        let type: String
        let number: Int?
        let content: [Item]?
    }

    /// A content item is either a bare string, `{ "text": "...", "poem": 1 }`,
    /// or a footnote marker `{ "noteId": 12 }` with no text at all. The footnote
    /// case is why this decodes tolerantly instead of demanding `text`.
    private enum Item: Decodable {
        case plain(String)
        case styled(String)

        private struct Payload: Decodable {
            let text: String?
            let noteId: Int?
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let text = try? container.decode(String.self) {
                self = .plain(text)
                return
            }
            self = .styled(try container.decode(Payload.self).text ?? "")
        }

        var text: String {
            switch self {
            case .plain(let text):  return text
            case .styled(let text): return text
            }
        }
    }

    // MARK: Book codes (USFM, as used by bible.helloao.org)

    private static let bookCodes: [String: String] = [
        "Genesis": "GEN",
        "Exodus": "EXO",
        "Leviticus": "LEV",
        "Numbers": "NUM",
        "Deuteronomy": "DEU",
        "Joshua": "JOS",
        "Judges": "JDG",
        "Ruth": "RUT",
        "1 Samuel": "1SA",
        "2 Samuel": "2SA",
        "1 Kings": "1KI",
        "2 Kings": "2KI",
        "1 Chronicles": "1CH",
        "2 Chronicles": "2CH",
        "Ezra": "EZR",
        "Nehemiah": "NEH",
        "Esther": "EST",
        "Job": "JOB",
        "Psalms": "PSA",
        "Proverbs": "PRO",
        "Ecclesiastes": "ECC",
        "Song of Solomon": "SNG",
        "Isaiah": "ISA",
        "Jeremiah": "JER",
        "Lamentations": "LAM",
        "Ezekiel": "EZK",
        "Daniel": "DAN",
        "Hosea": "HOS",
        "Joel": "JOL",
        "Amos": "AMO",
        "Obadiah": "OBA",
        "Jonah": "JON",
        "Micah": "MIC",
        "Nahum": "NAM",
        "Habakkuk": "HAB",
        "Zephaniah": "ZEP",
        "Haggai": "HAG",
        "Zechariah": "ZEC",
        "Malachi": "MAL",
        "Matthew": "MAT",
        "Mark": "MRK",
        "Luke": "LUK",
        "John": "JHN",
        "Acts": "ACT",
        "Romans": "ROM",
        "1 Corinthians": "1CO",
        "2 Corinthians": "2CO",
        "Galatians": "GAL",
        "Ephesians": "EPH",
        "Philippians": "PHP",
        "Colossians": "COL",
        "1 Thessalonians": "1TH",
        "2 Thessalonians": "2TH",
        "1 Timothy": "1TI",
        "2 Timothy": "2TI",
        "Titus": "TIT",
        "Philemon": "PHM",
        "Hebrews": "HEB",
        "James": "JAS",
        "1 Peter": "1PE",
        "2 Peter": "2PE",
        "1 John": "1JN",
        "2 John": "2JN",
        "3 John": "3JN",
        "Jude": "JUD",
        "Revelation": "REV",
    ]
}
