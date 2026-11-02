//
//  ChineseBibleStore.swift
//  Reveal
//
//  The Chinese Union Version of 1919 — all 66 books, bundled with the app.
//
//  Chinese used to come from bible.helloao.org's `cmn_cu1`, which is the 1989
//  new-punctuation edition: the United Bible Societies and the Hong Kong Bible
//  Society assert rights in that edition, and a "public domain" label on a
//  mirror does not transfer them. The 1919 text is public domain, so it ships
//  inside the app and reading a Chinese chapter never touches the network.
//
//  Text: 官話和合本, 1919 (the "神" edition — hence the full-width space before
//  the divine name). Characters converted to simplified; punctuation brought to
//  modern usage. Wording is unchanged.
//

import Foundation

actor ChineseBibleStore {
    static let shared = ChineseBibleStore()

    enum StoreError: LocalizedError {
        case missingResource
        case bookMissing(String)
        case chapterMissing(String, Int)

        var errorDescription: String? {
            switch self {
            case .missingResource:          return "The bundled Bible text is missing."
            case .bookMissing(let book):    return "No text for \(book)."
            case .chapterMissing(let book, let chapter): return "\(book) \(chapter) is not in the bundled text."
            }
        }
    }

    /// One `[chapter, verse, text]` row from the JSON bundle.
    private struct Row: Decodable {
        let chapter: Int
        let verse: Int
        let text: String

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            chapter = try container.decode(Int.self)
            verse = try container.decode(Int.self)
            text = try container.decode(String.self)
        }
    }

    private var all: [String: [Row]]?
    private var cache: [String: [Int: [BibleVerse]]] = [:]

    func chapter(usfm: String, number: Int, fallbackBookName: String) throws -> BibleChapter {
        let name = Self.bookNames[usfm] ?? fallbackBookName

        if let byChapter = cache[usfm], let verses = byChapter[number] {
            return BibleChapter(bookName: name, bookCode: usfm, chapterNumber: number, verses: verses)
        }

        let book = try load()[usfm] ?? []
        guard !book.isEmpty else { throw StoreError.bookMissing(usfm) }

        var byChapter: [Int: [BibleVerse]] = [:]
        for row in book {
            byChapter[row.chapter, default: []].append(
                BibleVerse(number: row.verse, heading: nil, text: row.text)
            )
        }
        cache[usfm] = byChapter

        guard let verses = byChapter[number], !verses.isEmpty else {
            throw StoreError.chapterMissing(usfm, number)
        }
        return BibleChapter(bookName: name, bookCode: usfm, chapterNumber: number, verses: verses)
    }

    /// Verse count and availability, for tests and for the empty state.
    func verseCount() throws -> Int {
        try load().values.reduce(0) { $0 + $1.count }
    }

    private func load() throws -> [String: [Row]] {
        if let all { return all }
        guard let url = Bundle.main.url(forResource: "ChineseBible1919", withExtension: "json") else {
            throw StoreError.missingResource
        }
        let decoded = try JSONDecoder().decode([String: [Row]].self, from: Data(contentsOf: url))
        all = decoded
        return decoded
    }

    // MARK: Book names

    static let bookNames: [String: String] = [
        "GEN": "创世记",
        "EXO": "出埃及记",
        "LEV": "利未记",
        "NUM": "民数记",
        "DEU": "申命记",
        "JOS": "约书亚记",
        "JDG": "士师记",
        "RUT": "路得记",
        "1SA": "撒母耳记上",
        "2SA": "撒母耳记下",
        "1KI": "列王纪上",
        "2KI": "列王纪下",
        "1CH": "历代志上",
        "2CH": "历代志下",
        "EZR": "以斯拉记",
        "NEH": "尼希米记",
        "EST": "以斯帖记",
        "JOB": "约伯记",
        "PSA": "诗篇",
        "PRO": "箴言",
        "ECC": "传道书",
        "SNG": "雅歌",
        "ISA": "以赛亚书",
        "JER": "耶利米书",
        "LAM": "耶利米哀歌",
        "EZK": "以西结书",
        "DAN": "但以理书",
        "HOS": "何西阿书",
        "JOL": "约珥书",
        "AMO": "阿摩司书",
        "OBA": "俄巴底亚书",
        "JON": "约拿书",
        "MIC": "弥迦书",
        "NAM": "那鸿书",
        "HAB": "哈巴谷书",
        "ZEP": "西番雅书",
        "HAG": "哈该书",
        "ZEC": "撒迦利亚书",
        "MAL": "玛拉基书",
        "MAT": "马太福音",
        "MRK": "马可福音",
        "LUK": "路加福音",
        "JHN": "约翰福音",
        "ACT": "使徒行传",
        "ROM": "罗马书",
        "1CO": "哥林多前书",
        "2CO": "哥林多后书",
        "GAL": "加拉太书",
        "EPH": "以弗所书",
        "PHP": "腓立比书",
        "COL": "歌罗西书",
        "1TH": "帖撒罗尼迦前书",
        "2TH": "帖撒罗尼迦后书",
        "1TI": "提摩太前书",
        "2TI": "提摩太后书",
        "TIT": "提多书",
        "PHM": "腓利门书",
        "HEB": "希伯来书",
        "JAS": "雅各书",
        "1PE": "彼得前书",
        "2PE": "彼得后书",
        "1JN": "约翰一书",
        "2JN": "约翰二书",
        "3JN": "约翰三书",
        "JUD": "犹大书",
        "REV": "启示录",
    ]
}
