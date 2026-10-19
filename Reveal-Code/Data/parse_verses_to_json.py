#!/usr/bin/env python3
"""Parse Bible verses (collected) in order (final).md and output JSON for Reveal app."""
import re
import json

INPUT_MD = "Bible verses (collected) in order (final).md"
OUTPUT_JSON = "RevealCards_320.json"

FIXED_ACTION = "May we not only hear the Word, but courageously live out the Scripture we learned today in the way we speak, love, and act."

# Normalize book names to match BibleAPIService bookIdMap
BOOK_NORMALIZE = {
    "Psalm": "Psalms",
}

def parse_reference(ref_str):
    """Parse 'Genesis 1:1' or 'Proverbs 3:5-6' or '1 Corinthians 13:4' into book, chapter, verse or startVerse/endVerse."""
    ref_str = ref_str.strip()
    # Replace en-dash with hyphen for verse range
    ref_str = ref_str.replace("\u2013", "-").replace("\u2014", "-")
    # Last part is "chapter:verse" or "chapter:start-end"
    parts = ref_str.rsplit(" ", 1)
    if len(parts) != 2:
        return None
    book, ch_verse = parts
    book = book.strip()
    book = BOOK_NORMALIZE.get(book, book)
    if ":" not in ch_verse:
        return None
    ch_part, verse_part = ch_verse.split(":", 1)
    try:
        chapter = int(ch_part)
    except ValueError:
        return None
    if "-" in verse_part:
        v = verse_part.split("-")
        if len(v) != 2:
            return None
        try:
            start_v = int(v[0].strip())
            end_v = int(v[1].strip())
            return {"book": book, "chapter": chapter, "startVerse": start_v, "endVerse": end_v}
        except ValueError:
            return None
    try:
        verse = int(verse_part.strip())
        return {"book": book, "chapter": chapter, "verse": verse}
    except ValueError:
        return None

def make_id(ref):
    if "verse" in ref:
        return f"{ref['book'].lower().replace(' ', '-')}-{ref['chapter']}-{ref['verse']}"
    return f"{ref['book'].lower().replace(' ', '-')}-{ref['chapter']}-{ref['startVerse']}-{ref['endVerse']}"

def main():
    with open(INPUT_MD, "r", encoding="utf-8") as f:
        lines = f.readlines()

    cards = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Verse line: * ... (Book Chapter:Verse, WEB)
        if line.strip().startswith("* ") and ", WEB)" in line and "(" in line:
            match = re.search(r'\(([^)]+),\s*WEB\)', line)
            if match:
                ref_str = match.group(1).strip()
                ref = parse_reference(ref_str)
                if ref:
                    # Next non-empty line should be the question (starts with -)
                    question = ""
                    j = i + 1
                    while j < len(lines):
                        next_line = lines[j].strip()
                        if not next_line:
                            j += 1
                            continue
                        if next_line.startswith("- "):
                            question = next_line[2:].strip()
                            break
                        if next_line.startswith("* "):
                            break
                        j += 1
                    card = {
                        "id": make_id(ref),
                        "reference": ref,
                        "en": {
                            "question": question,
                            "action": FIXED_ACTION,
                        },
                        "zh": {
                            "question": question,
                            "action": FIXED_ACTION,
                        },
                    }
                    cards.append(card)
        i += 1

    out = {"schema_version": "1.0", "cards": cards}
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    print(f"Wrote {len(cards)} cards to {OUTPUT_JSON}")

if __name__ == "__main__":
    main()
