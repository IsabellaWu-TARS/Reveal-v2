# 卡片数据：Markdown 格式说明（一语言一文件）

## 推荐格式：Markdown (.md)

- **优点**：结构清晰、易解析、可读性好，且 Google Doc 可导出为 .md。
- **约定**：**一个语言一个文件**，例如 `cards_en.md`（英文）、`cards_zh.md`（中文）。
- **重要**：两个文件里的**卡片数量、顺序必须一致**，程序按「第几张」一一对应合并中英。

---

## 每个文件的写法

每张卡占一块，用二级标题写**经文索引**，下面两行写 **Question:** 和 **Action:**。

### 单节经文

```markdown
## John 3:16
Question: How does knowing God's love change the way you live today?
Action: Share God's love with someone who needs encouragement today.

## Psalm 23:1
Question: In what areas of your life do you need to trust God as your shepherd?
Action: Write down one worry and surrender it to God's care.
```

### 多节经文（一段）

```markdown
## Proverbs 3:5-6
Question: Where are you relying on your own understanding instead of trusting God?
Action: Choose one decision to surrender to God's wisdom today.
```

### 书卷名带数字（如哥林多前书）

```markdown
## 1 Corinthians 13:4
Question: In which relationship can you show more patience or kindness today?
Action: Choose one person to serve with a simple act of kindness.
```

### 规则小结

1. **每张卡一块**：以 `## ` 开头的一行是「经文索引」，下面必须有 `Question:` 和 `Action:` 各一行。
2. **经文索引**支持：
   - 单节：`Book Chapter:Verse`（如 `John 3:16`、`Psalm 23:1`）
   - 多节：`Book Chapter:StartVerse-EndVerse`（如 `Proverbs 3:5-6`）
   - 书卷名可带数字和空格（如 `1 Corinthians 13:4`）
3. **Question:** 和 **Action:** 后面紧跟内容，整行都会被视为该字段内容。
4. 卡片与卡片之间可空一行，便于阅读；解析时会按 `## ` 分块。
5. 书卷名写 **Psalm** 会被程序自动规范为 **Psalms**（与 Bible API 一致）；其余书卷名需与支持列表一致（如 John, Proverbs, 1 Corinthians）。

---

## 两个文件如何对应

- **cards_en.md**：所有标题与内容为英文。
- **cards_zh.md**：所有标题与内容为中文；**块的顺序要和英文文件完全一致**（第 1 张、第 2 张……一一对应）。

程序会按「第 i 张」把英文的 question/action 和中文的 question/action 合并成一条卡片数据，所以**不要**在中文文件里调换顺序或增删卡片。

---

## 从 Google Doc 导出为 Markdown

1. 在 Google Doc 里按上面格式写好（可先写英文再写中文，或分两个文档）。
2. 导出：**文件 → 下载 → Markdown (.md)**。
3. 得到两个文件后，放入工程的 `Reveal/Resources/` 并加入 App Target，或把内容贴给开发者生成/调试。

若无法直接导出 .md，可先导出 **纯文本 (.txt)**，保持「每块：一行 ## 经文、一行 Question:、一行 Action:」的结构，程序也可用同一套解析逻辑读取。

---

## 在 Xcode 中使用

1. 将 `cards_en.md` 和 `cards_zh.md` 放到工程目录（如 `Reveal/Resources/`）。
2. 在 Xcode 中把这两个文件加入 **Reveal** Target（勾选 Target Membership）。
3. 代码通过 `CardContentLoader.loadFromMarkdown(bundle: .main)` 读取并合并为 `[CardContentItem]`，再配合 Bible API 按索引取经文、按语言取 question/action 即可。
