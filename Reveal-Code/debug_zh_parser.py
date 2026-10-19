#!/usr/bin/env python3
import re

text = "起初，神创造了天地。（创世记 1:1，和合本）"

# Current failing pattern
pat_lazy = r'[（(]([^）)]+?)\s+(\d+):(\d+)[\-\d]*[）)]'
m = re.search(pat_lazy, text)
print(f"Lazy pattern: {m}")

# Fixed greedy pattern
pat_greedy = r'[（(]([^）)]*)\s+(\d+):(\d+)[\-\d]*[）)]'
m = re.search(pat_greedy, text)
print(f"Greedy pattern: {m}")
if m:
    print(f"  Groups: '{m.group(1)}', ch={m.group(2)}, v={m.group(3)}")

# Also test with range verse
text2 = "我又要叫你和女人彼此为仇。（创世记 3:15，和合本）"
m2 = re.search(pat_greedy, text2)
print(f"\nRange verse: {m2}")
if m2:
    print(f"  Groups: '{m2.group(1)}', ch={m2.group(2)}, v={m2.group(3)}")

# Check for Chinese space
print(f"\nBytes around space in Chinese text:")
idx = text.find(' ')
if idx >= 0:
    print(f"  Space at index {idx}: {repr(text[idx-5:idx+5])}")
    print(f"  Space char code: {ord(text[idx])}")
