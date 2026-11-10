# Reveal 卡片数据：JSON 规范与 Google Doc 整理指南

## 一、背后逻辑拆解

### 1. 经文：只存「索引」，不存经文正文

- **经文正文**由 **Bible API** 按语言（英文 / 中文）拉取，不写在 JSON 里。
- JSON 里只存「索引」：**书卷名 + 章 + 节**（或节范围），用来调 API。
- 这样做的原因：
  - 避免在 app 里存两份（中/英）冗长经文，减少出错。
  - 翻译更新时只需 API 更新，不用改 JSON。
  - 书卷名统一用英文（与现有 `BibleAPIService` 的 `bookIdMap` 一致），避免写错。

### 2. 问题与行动：中英分开，绝不混用

- 每条卡片都有 **en** 和 **zh** 两个对象。
- **en**：只放英文的 `question`、`action`。
- **zh**：只放中文的 `question`、`action`。
- App 根据用户语言选 `en` 或 `zh`，不会混用。

### 3. 随机且不重复

- 从 JSON 读入的是「卡片列表」。
- App 逻辑：
  - 把列表打乱（shuffle）或维护一个「未出现队列」；
  - 每次抽下一张从队列里取，取完再重新打乱，保证**在整轮内不重复**；
  - 经文本身是「按卡片」随机出现的，因为抽到哪张卡是随机的。

### 4. 数据流小结

```
JSON 文件
  → 卡片列表 [ { reference: { book, chapter, verse }, en: { question, action }, zh: { question, action } }, ... ]
  → 随机选一张卡（且本轮不重复）
  → 用 reference 调 Bible API 取经文（英文或中文）
  → 用 en / zh 取当前语言的问题与行动
  → 显示在界面上
```

---

## 二、JSON 文件怎么写

### 根结构

```json
{
  "schema_version": "1.0",
  "cards": [ ... ]
}
```

- `schema_version`：可选，方便以后格式升级。
- `cards`：数组，每个元素是一张卡片的完整数据。

### 单张卡片结构

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 建议 | 唯一标识，如 `"john-3-16"`，方便排查、去重。 |
| `reference` | object | 是 | 经文索引，见下表。 |
| `en` | object | 是 | 英文问题与行动。 |
| `zh` | object | 是 | 中文问题与行动。 |

### reference（经文索引）

**单节：**

```json
"reference": {
  "book": "John",
  "chapter": 3,
  "verse": 16
}
```

**多节（一段经文）：**

```json
"reference": {
  "book": "Proverbs",
  "chapter": 3,
  "startVerse": 5,
  "endVerse": 6
}
```

- `book`：英文书卷名，必须和下面「支持的书卷」一致。
- `chapter`：章号，数字。
- `verse`：单节时用。
- `startVerse` / `endVerse`：多节时用，API 会取这一段。

### en / zh 结构

```json
"en": {
  "question": "英文反思问题",
  "action": "英文行动建议"
},
"zh": {
  "question": "中文反思问题",
  "action": "中文行动建议"
}
```

- 不要在中英之间复制粘贴错列，建议先填完一列语言再填另一列。

### 支持的书卷（与 Bible API 对应）

以下书卷名可直接用在 `reference.book`（大小写一致）：

- Genesis, Exodus, Joshua, Psalms, Proverbs, Isaiah, Jeremiah  
- Matthew, Mark, Luke, John, Acts  
- Romans, 1 Corinthians, Ephesians, Philippians, Revelation  

在代码里 `BibleAPIService.bookIdMap` 已包含上述书卷；若需更多书卷，可在此映射表中增加。

---

## 三、Google Doc 里如何整理、如何给我

### 方式 A：表格（推荐）

在 Google Doc 里建一个**表格**，每行一张卡片，列如下（列顺序保持一致即可）：

| Book | Chapter | Verse 或 StartVerse | EndVerse（可选） | Question EN | Question ZH | Action EN | Action ZH |
|------|---------|----------------------|------------------|-------------|-------------|-----------|-----------|
| John | 3 | 16 | | How does knowing... | 认识神的爱... | Share God's love... | 今天与需要鼓励的人... |
| Proverbs | 3 | 5 | 6 | Where are you... | 你在哪些地方... | Choose one decision... | 选择今天的一个决定... |

- **Verse**：单节时填一节，多节时留空或只填起始节，并在 **EndVerse** 填结束节。
- 整理好后可以：
  - **复制整张表**贴到文档里发给我，或  
  - **导出为 CSV**（文件 → 下载 → 逗号分隔值），把 CSV 内容贴出来或上传。

这样我可以按列解析，帮你生成标准 JSON，并保证中英对应不错。

### 方式 B：按行纯文本

若不用表格，可以每张卡一段，格式固定即可，例如：

```
Book: John
Chapter: 3
Verse: 16
Question EN: How does knowing God's love change the way you live today?
Question ZH: 认识神的爱如何改变你今日的生活？
Action EN: Share God's love with someone who needs encouragement today.
Action ZH: 今天与需要鼓励的人分享神的爱。
---
Book: Proverbs
...
```

发给我时保持「每段一张卡、字段名一致」，我也可以据此生成 JSON。

### 注意事项

1. **书卷名**：一律用英文，和上面支持列表一致（如 John, Psalms, Proverbs）。
2. **中英对应**：同一行的 Question EN 与 Question ZH 必须是同一道题；Action 同理。
3. **多节经文**：同一行里 StartVerse / EndVerse 与 Book、Chapter 对应同一段经文。
4. **不要**在 JSON 里写经文正文，只写索引；正文由 App 用索引调 Bible API 获取。

---

## 四、示例 JSON 文件位置与用法

- 项目里已放了一份**示例 JSON**：`Reveal/Resources/CardsDataSchema.json`。  
- 结构可直接当作「模板」：把你 Google Doc 整理好的数据按同样结构填进去即可。  
- 之后在 App 里会：  
  - 读取该 JSON 得到 `cards` 数组；  
  - 用 `reference` 调中/英 Bible API 取经文；  
  - 用 `en`/`zh` 按语言显示问题与行动；  
  - 用「随机且不重复」的逻辑选下一张卡。

如果你把 Google Doc 的表格（或按行格式）贴出来或导出 CSV 发给我，我可以按上述规范帮你生成完整的、可直接放进项目的 JSON 文件内容，并保证中英文不错位。

---

## 五、JSON 在 App 中的使用（后续实现）

- 将 `CardsDataSchema.json`（或你导出的 `RevealCards.json`）放入工程，并勾选加入 App Target，这样 `Bundle.main.url(forResource:withExtension:)` 才能读到。
- App 逻辑概要：
  1. 启动时解析 JSON → 得到 `[CardItem]`。
  2. 维护一个「待展示队列」：用当前列表 shuffle 后作为队列，每次取一张，取完再 shuffle 再循环，保证随机且不重复。
  3. 展示某张卡时：用 `reference` 调 `BibleAPIService` 取经文（按当前语言 EN/ZH）；用 `en`/`zh` 取当前语言的 `question` 和 `action`。
  4. 卡片样式（颜色等）仍可随机，与「哪条数据」无关；随机且不重复的是「数据卡片」本身。
