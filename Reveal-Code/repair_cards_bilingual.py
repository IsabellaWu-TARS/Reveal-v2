#!/usr/bin/env python3
"""
Repair RevealCards_bilingual.json from the two canonical source files in Card Content/.

Why this exists: the original generator paired "verse line / next line" per card and
mistook book-header lines ("1 Samuel (13)") for verse text. That shifted the English
fields by one slot after each book header, producing 38 records with
book="", id="-1-1", a book name in en.verse, verse text in en.question, and 10 pure
phantom duplicates (324 records for 314 real verses).

This parser is anchor-based instead of position-based: a verse line is any line that
ENDS with a parenthetical reference. The reflection question is the next non-empty,
non-reference line. That cannot drift.

Usage:
    python3 repair_cards_bilingual.py --dry-run     # report only
    python3 repair_cards_bilingual.py               # write JSON (keeps .bak)
"""
import argparse
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EN_SRC = ROOT / "Card Content" / "BibleVerses.txt"
ZH_SRC = ROOT / "Card Content" / "中文圣经verses.txt"
OUT = ROOT / "Reveal" / "Resources" / "RevealCards_bilingual.json"

EN_REF = re.compile(r"\(([A-Za-z0-9 ]+?)\s+(\d+):(\d+)(?:[-\u2013,]\s*\d+)?[^)]*\)\s*$")
ZH_REF = re.compile(r"[（(]([^）)]+?)\s+(\d+):(\d+)(?:[-\u2013,]\s*\d+)?[^）)]*[）)]\s*$")
ZH_TRAIL = re.compile(r"[（(][^）)]*[）)]\s*$")

ZH_BOOKS = {
    "创世记": "Genesis", "出埃及记": "Exodus", "利未记": "Leviticus",
    "民数记": "Numbers", "申命记": "Deuteronomy", "约书亚记": "Joshua",
    "士师记": "Judges", "路得记": "Ruth", "撒母耳记上": "1 Samuel",
    "撒母耳记下": "2 Samuel", "列王纪上": "1 Kings", "列王纪下": "2 Kings",
    "历代志上": "1 Chronicles", "历代志下": "2 Chronicles", "以斯拉记": "Ezra",
    "尼希米记": "Nehemiah", "以斯帖记": "Esther", "约伯记": "Job",
    "诗篇": "Psalm", "箴言": "Proverbs", "传道书": "Ecclesiastes",
    "雅歌": "Song of Solomon", "以赛亚书": "Isaiah", "耶利米书": "Jeremiah",
    "耶利米哀歌": "Lamentations", "哀歌": "Lamentations", "以西结书": "Ezekiel",
    "但以理书": "Daniel", "何西阿书": "Hosea", "约珥书": "Joel", "阿摩司书": "Amos",
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

SKIP_PREFIX = ("行动", "Action", "资料来源", "版权", "许可", "来源：")


def parse_source(path: Path, ref_pat: re.Pattern, is_zh: bool):
    """Return (ordered list of (book, chapter, verse), dict key -> (verse, question))."""
    lines = [l.strip() for l in path.read_text(encoding="utf-8").splitlines()]
    order, data, pending = [], {}, None

    for line in lines:
        if not line:
            continue
        m = ref_pat.search(line)
        if m:
            raw_book = m.group(1).strip()
            book = ZH_BOOKS.get(raw_book, raw_book) if is_zh else raw_book
            key = (book, int(m.group(2)), int(m.group(3)))
            verse = line[: m.start()].strip()
            if is_zh:
                verse = ZH_TRAIL.sub("", line) if not verse else verse
                verse = verse.rstrip("。")      # card style: no trailing full stop
            verse = re.sub(r"^[\s,，、.。]+", "", verse).strip()
            if key not in data:            # first occurrence wins (source has 3 dup ZH refs)
                order.append(key)
                data[key] = {"verse": verse, "question": ""}
            pending = key
            continue
        if pending and not data[pending]["question"] and not line.startswith(SKIP_PREFIX):
            data[pending]["question"] = line
            pending = None
    return order, data


def slug(book: str, chapter: int, verse: int) -> str:
    return f"{book.lower().replace(' ', '-')}-{chapter}-{verse}"


def build():
    en_order, en = parse_source(EN_SRC, EN_REF, is_zh=False)
    _, zh = parse_source(ZH_SRC, ZH_REF, is_zh=True)

    old = json.loads(OUT.read_text(encoding="utf-8"))
    old_by_key = {(c["book"], c["chapter"], c["verse"]): c for c in old if c.get("book")}

    cards, problems = [], []
    for key in en_order:
        book, ch, v = key
        e, z = en[key], zh.get(key)
        prev = old_by_key.get(key)
        if z is None and prev:                       # keep previously paired Chinese text
            z = {
                "verse": prev["zh"]["verse"],
                "question": prev["zh"].get("question", ""),
            }
        if not e["verse"]:
            problems.append(f"{book} {ch}:{v}: empty English verse")
        if not e["question"]:
            problems.append(f"{book} {ch}:{v}: empty English question")
        if z is None or not z["verse"]:
            problems.append(f"{book} {ch}:{v}: no Chinese verse")
        cards.append({
            "id": slug(book, ch, v),
            "reference": f"{book} {ch}:{v}, WEB",
            "book": book,
            "chapter": ch,
            "verse": v,
            "en": {
                "verse": e["verse"],
                "question": e["question"],
                "action": "How can I live according to this verse today?",
            },
            "zh": {
                "verse": z["verse"] if z else "",
                "question": z["question"] if z else "",
                "action": "今天，我如何让这节经文在生命中活出来？",
            },
        })
    return cards, problems, old


def check(cards, old):
    errs = []
    ids = [c["id"] for c in cards]
    if len(set(ids)) != len(ids):
        errs.append(f"duplicate ids: {len(ids) - len(set(ids))}")
    if any(not c["book"] for c in cards):
        errs.append("empty book field")
    if any(re.search(r"\(\w[\w\s]*\d+:\d+", c["en"]["verse"]) for c in cards):
        errs.append("reference still embedded in en.verse")
    if any(re.search(r",\s*(WEB|KJV)\)\s*$", c["en"]["question"]) for c in cards):
        errs.append("verse text sitting in en.question")
    if any(c["reference"] and ":" not in c["reference"] for c in cards):
        errs.append("malformed reference")
    # every card that existed before and still exists must keep its id
    old_ids = {(c["book"], c["chapter"], c["verse"]): c["id"] for c in old if c.get("book")}
    for c in cards:
        k = (c["book"], c["chapter"], c["verse"])
        if k in old_ids and old_ids[k] != c["id"]:
            errs.append(f"id changed for {k}: {old_ids[k]} -> {c['id']}")
    return errs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    cards, problems, old = build()
    errs = check(cards, old)

    print(f"source EN verses: {len(cards)}   existing cards: {len(old)}")
    print(f"problems: {len(problems)}")
    for p in problems[:20]:
        print("  !", p)
    print(f"validation errors: {len(errs)}")
    for e in errs[:20]:
        print("  !", e)

    if args.dry_run:
        print("\n--dry-run: nothing written")
        return 0 if not errs else 2
    if errs:
        print("\nrefusing to write: fix validation errors first")
        return 2

    shutil.copy2(OUT, OUT.with_suffix(".json.bak"))
    OUT.write_text(json.dumps(cards, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nwrote {OUT} ({len(cards)} cards); backup at {OUT.with_suffix('.json.bak').name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
