#!/usr/bin/env python3
"""
Parse Card Content text files and generate bilingual JSON for Reveal app.
"""
import json
import re

BOOK_NAME_MAP = {
    "创世记": "Genesis", "出埃及记": "Exodus", "利未记": "Leviticus",
    "民数记": "Numbers", "申命记": "Deuteronomy", "约书亚记": "Joshua",
    "士师记": "Judges", "路得记": "Ruth", "撒母耳记上": "1 Samuel",
    "撒母耳记下": "2 Samuel", "列王纪上": "1 Kings", "列王纪下": "2 Kings",
    "历代志上": "1 Chronicles", "历代志下": "2 Chronicles", "以斯拉记": "Ezra",
    "尼希米记": "Nehemiah", "以斯帖记": "Esther", "约伯记": "Job",
    "诗篇": "Psalms", "箴言": "Proverbs", "传道书": "Ecclesiastes",
    "雅歌": "Song of Solomon", "以赛亚书": "Isaiah", "耶利米书": "Jeremiah",
    "耶利米哀歌": "Lamentations", "以西结书": "Ezekiel", "但以理书": "Daniel",
    "何西阿书": "Hosea", "约珥书": "Joel", "阿摩司书": "Amos",
    "俄巴底亚书": "Obadiah", "约拿书": "Jonah", "弥迦书": "Micah",
    "那鸿书": "Nahum", "哈巴谷书": "Habakkuk", "西番雅书": "Zephaniah",
    "哈该书": "Haggai", "撒迦利亚书": "Zechariah", "玛拉基书": "Malachi",
    "马太福音": "Matthew", "马可福音": "Mark", "路加福音": "Luke",
    "约翰福音": "John", "使徒行传": "Acts", "罗马书": "Romans",
    "哥林多前书": "1 Corinthians", "哥林多后书": "2 Corinthians",
    "加拉太书": "Galatians", "以弗所书": "Ephesians", "腓立比书": "Philippians",
    "歌罗西书": "Colossians", "帖撒罗尼迦前书": "1 Thessalonians",
    "帖撒罗尼迦后书": "2 Thessalonians", "提摩太前书": "1 Timothy",
    "提摩太后书": "2 Timothy", "提多书": "Titus", "腓利门书": "Philemon",
    "希伯来书": "Hebrews", "雅各书": "James", "彼得前书": "1 Peter",
    "彼得后书": "2 Peter", "约翰一书": "1 John", "约翰二书": "2 John",
    "约翰三书": "3 John", "犹大书": "Jude", "启示录": "Revelation",
}

EN_BOOKS = {"Genesis","Exodus","Leviticus","Numbers","Deuteronomy","Joshua","Judges",
    "Ruth","1 Samuel","2 Samuel","1 Kings","2 Kings","1 Chronicles","2 Chronicles",
    "Ezra","Nehemiah","Esther","Job","Psalms","Proverbs","Ecclesiastes",
    "Song of Solomon","Isaiah","Jeremiah","Lamentations","Ezekiel","Daniel",
    "Hosea","Joel","Amos","Obadiah","Jonah","Micah","Nahum","Habakkuk",
    "Zephaniah","Haggai","Zechariah","Malachi","Matthew","Mark","Luke","John",
    "Acts","Romans","1 Corinthians","2 Corinthians","Galatians","Ephesians",
    "Philippians","Colossians","1 Thessalonians","2 Thessalonians","1 Timothy",
    "2 Timothy","Titus","Philemon","Hebrews","James","1 Peter","2 Peter",
    "1 John","2 John","3 John","Jude","Revelation"}

def is_book_header(line):
    s = line.strip()
    if re.match(r'^[A-Za-z\s]+\(\d+\)$', s):
        return True
    if re.match(r'^[\u4e00-\u9fff\s]+\(\d+\)$', s):
        return True
    if s in EN_BOOKS:
        return True
    if s in BOOK_NAME_MAP:
        return True
    return False

def parse_ref(text):
    # English: (Genesis 1:1, WEB) or (Genesis 1:1-3, WEB)
    en_pat = r'\(([A-Za-z\s]+)\s+(\d+):(\d+)[\-\d]*[\s,]'
    m = re.search(en_pat, text)
    if m:
        return m.group(1).strip(), int(m.group(2)), int(m.group(3))
    
    # Chinese: （创世记 1:1，和合本）or （启示录 1:7，CUV）
    # Key fix: use [^）]* instead of [\-\d]* between verse and closing paren
    zh_pat = r'[（(]([^）)]+?)\s+(\d+):(\d+)[^）]*[）)]'
    m = re.search(zh_pat, text)
    if m:
        book_cn = m.group(1).strip()
        return BOOK_NAME_MAP.get(book_cn, book_cn), int(m.group(2)), int(m.group(3))
    return None

def clean_verse(text, is_zh=False):
    s = re.sub(r'\s*[（(][^）)]*[）)]\s*$', '', text)
    if is_zh:
        s = re.sub(r'[，,]\s*(CUV|和合本)\s*$', '', s)
    else:
        s = re.sub(r'[，,]\s*(WEB|KJV)\s*$', '', s)
    return s.strip()

def parse_file(path, is_zh=False):
    cards = []
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    book_en = None
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line or line.startswith('行动：'):
            i += 1
            continue
        if is_book_header(line):
            if line == "启示录 (Revelation)":
                book_en = "Revelation"
            elif '(' in line:
                part = line.split('(')[0].strip()
                book_en = BOOK_NAME_MAP.get(part, part) if is_zh else part
            else:
                book_en = BOOK_NAME_MAP.get(line, line) if is_zh else line
            i += 1
            continue
        if re.match(r'^\d+\s*(Verses|节)$', line):
            i += 1
            continue
        if book_en:
            verse_line = line
            i += 1
            question = ""
            if i < len(lines):
                nxt = lines[i].strip()
                if nxt and not is_book_header(nxt) and not nxt.startswith('行动：'):
                    question = nxt
                    i += 1
            ref = parse_ref(verse_line)
            if ref:
                b, ch, v = ref
                cards.append({
                    "reference": f"{b} {ch}:{v}",
                    "book": b, "chapter": ch, "verse": v,
                    "en_verse": clean_verse(verse_line, False) if not is_zh else "",
                    "zh_verse": clean_verse(verse_line, True) if is_zh else "",
                    "en_question": question if not is_zh else "",
                    "zh_question": question if is_zh else "",
                })
            else:
                print(f"WARN: no ref in: {verse_line[:70]}")
        else:
            i += 1
    return cards

en = parse_file('/Users/IsabellaGranger/Desktop/💡Startupss/Reveal Mashal/Reveal-Code/Card Content/BibleVerses.txt', False)
zh = parse_file('/Users/IsabellaGranger/Desktop/💡Startupss/Reveal Mashal/Reveal-Code/Card Content/中文圣经verses.txt', True)
print(f"EN={len(en)}, ZH={len(zh)}")

merged = {}
for c in en:
    merged[c["reference"]] = c
for c in zh:
    if c["reference"] in merged:
        merged[c["reference"]]["zh_verse"] = c["zh_verse"]
        merged[c["reference"]]["zh_question"] = c["zh_question"]
    else:
        merged[c["reference"]] = c

out = []
for ref, c in merged.items():
    out.append({
        "id": ref.lower().replace(" ", "-").replace(":", "-"),
        "reference": c["reference"],
        "book": c["book"],
        "chapter": c["chapter"],
        "verse": c["verse"],
        "en": {
            "verse": c["en_verse"],
            "question": c["en_question"],
            "action": "How can I live according to this verse today?"
        },
        "zh": {
            "verse": c["zh_verse"],
            "question": c["zh_question"],
            "action": "今天，我如何让这节经文在生命中活出来？"
        }
    })

path = '/Users/IsabellaGranger/Desktop/💡Startupss/Reveal Mashal/Reveal-Code/Reveal/Resources/RevealCards_bilingual.json'
with open(path, 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

both = sum(1 for c in out if c["en"]["verse"] and c["zh"]["verse"])
print(f"Generated {len(out)} cards ({both} with both languages)")
if out:
    print("\nSample:")
    print(json.dumps(out[0], ensure_ascii=False, indent=2))
