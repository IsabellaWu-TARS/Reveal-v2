# Reveal · 搭建记录 / Build Story

> 视频脚本素材 · 中英对照 · 2026 年 10 月 19 日 → 11 月 11 日
> Chinese first, English mirror right below each part.

---

## 一句话 / In one line

**每天一张经文卡片：打开、读、翻面想一想、合上。三周半里最难的不是写代码，是「哪一版经文法律上能用」和「一张卡片到底该长什么样」。**

**A daily scripture card: open, read, flip to reflect, close. Three and a half weeks. The hard part was never the code — it was which edition of the Bible we were allowed to use, and what the card should look like.**

---

## 一、用户看到的五个动作 / What the person actually does

1. **打开** —— 启动动画是一片叶子，然后今天那一张卡片浮出来
2. **读** —— 正面：一句经文、出处、右上角收藏星
3. **翻** —— 点一下，3D 翻转；背面是「默想」：一个问题、一个行动
4. **走开一点** —— 左上角看书（整章经文），右上角看日历（哪天读过、收藏、笔记）
5. **分享** —— 把这一张卡导成图片发出去

**The whole product is five gestures: open, read, flip, wander, share.**

---

## 二、背后怎么跑 / How it actually works

### 2.1 今天给哪一张？/ Which card is "today"?

这里没有运行时随机 —— **随机只发生一次，然后永远固定**。

- 314 张卡用固定种子 `0x5EED_0BEE_F00D_1234` 打乱成一副牌，只洗一次
- 日期换算成「自 2001-01-01 起第几天」，再对牌堆取模
- 同一天 → 永远同一张；换手机、重装、换时区 → 还是同一张
- 选中后写进存档（日期键 + 卡片 id）；第二天自然切到下一张
- 跨午夜：监听系统的「日历日变更」，App 挂在后台也会换卡
- 存档和当前日期对不上（用户改了系统时间）→ 自动重算，不会卡住

> **重点**：用户感受到的是「今天这张」，工程上是一条可复现的公式。可复现，才能测，也才能让所有人看到同一张。

**No randomness at runtime. The deck is shuffled once with a fixed seed; the day key picks an index; the choice is written to disk so it survives relaunch, reinstall and time-zone changes.**

### 2.2 为什么每张卡颜色不同？/ Why every card has its own colour

- 卡片 id（`book-chapter-verse`）做 FNV-1a 哈希 → 落进 **24 个卡片名 / 13 组渐变**
- 颜色跟着**卡片**走，不跟着日期走：翻到别的经文就换色，同一张卡重开颜色不跳
- 正反面共用同一个配色，翻转时颜色不变
- 13 组里 12 组浅色、1 组深色；浅色的白字有一个 **2.2:1 的地板**（见难关三）

**The colour is hashed from the card id, not the date: one verse always wears one gradient, the back matches the front, and the flip never changes hue.**

### 2.3 正反面 / Front and back

- **正面**：小标题、经文、出处、收藏星。字号按卡片宽度算，超长经文自动缩小而不是溢出
- **背面**：`Reflection` 标题 + `Reflect`（问题）+ `Action`（行动）
- 两面共用 `CardTypeScale`：同一套公式、同一个 `xLarge` 上限 —— 系统字体调大，两面一起长，卡片本身尺寸不变
- 文字三档：`automatic`（随卡片深浅选白字或墨字）、`white`、`ink`/自定义

**Both faces derive type from the card's width and stop growing at the same Dynamic Type ceiling, so the card never changes shape — only the type inside it.**

### 2.4 整章经文怎么来 / Where the chapter text comes from

- **英文**：`https://bible.helloao.org/api/eng_web/<USFM>/<章>.json`，内存缓存 + `URLCache`；失败显示提示与「重试」，当天卡片照常可读
- **中文**：**全本内置**，66 卷一个 JSON，按卷懒加载 + 缓存，**完全不联网**
- 点经文出处 → 进整章，今天那一节高亮

**English chapters are fetched over HTTPS and cached; Chinese chapters ship inside the app and never touch the network. That split is a licensing decision, not an optimisation.**

### 2.5 语言与字形 / Language and script

- 界面语言 `en` / `zh-Hans`，两套 `Localizable.strings`，**96 : 96 完全对齐**
- 经文另有「简体 / 繁體」开关：1919 原文存繁体，简体是**逐字转换**（4,057 条单字表，无词组替换）
- 因此同一节在两个字形下**字数完全相同** —— 有一条测试专门守这件事

**Language is one setting; script is another. The 1919 text is stored in traditional and converted character-by-character, so a simplified verse is provably the same text — enforced by a test that compares lengths.**

### 2.6 提醒 / Reminders

- **本地通知**，不是推送：不需要服务器，不上传任何东西
- 默认 20:00，可改；自定义提示音 `reveal_chime.caf`
- 每次打开 App 重新确认还在队列里（系统会清理），用户关掉就跳过

**A local notification at the hour you pick, re-asserted on launch because the system quietly drops them — no server, no account, nothing leaves the phone.**

### 2.7 日历与记录 / Calendar and memory

- 记录「打开过」的日期，日历上标出哪天有经文
- 收藏、笔记全部本地存储
- 日历里**过去的日期保留当时的配色**，只有今天跟随你选的颜色

**Past days keep the palette they were shown with; only today follows the colour you picked. Memory shouldn't repaint itself.**

### 2.8 分享 / Sharing

- 卡片渲染成 PNG（360×572 @3x），带缩略图交给系统分享面板
- 导出图里没有收藏星和「点击返回」这类界面提示 —— 导出的是一张卡，不是一张截图

**The export is the artwork, not a screenshot: interface hints are stripped before rendering.**

### 2.9 启动顺序 / Launch sequence

```
SplashView（叶子 + 品牌绿）
  └─ 第一次打开 → 选语言（English / 简体中文）
       └─ 5 步引导：真实界面 + 遮罩挖洞，点空白处前进
            └─ HomeView
```

第一次启动的引导**直接渲染真实的 HomeView**，在它上面挖洞指出每个按钮 —— 不是画一张示意图。

**First launch runs on the real HomeView with a mask cut over each control, so the guide teaches the actual buttons, not a mock-up.**

---

## 三、App 现在的结构 / The codebase today

```
Reveal-Code/
├── Reveal/
│   ├── RevealApp.swift              启动、页面切换、splash 与引导的编排
│   ├── BibleAPIService.swift        英文整章：请求 + 解析 + 缓存
│   ├── ChineseBibleStore.swift      中文全本：按卷懒加载
│   ├── NotificationScheduler.swift  本地提醒：排程 / 重排队 / 提示音
│   ├── Design/                      外观与排版的地基
│   │   ├── CardStyle.swift          13 组渐变 + 白字对比度地板
│   │   ├── CardTint.swift           用户自定义配色
│   │   ├── CardInk.swift            白字 / 墨字 / 自动 三档
│   │   ├── CardTypeScale.swift      正反面共用的一套字号
│   │   ├── CoachAnchors.swift       引导层定位控件
│   │   └── Design.swift · Shapes.swift · AppLocale.swift · ScriptPreference.swift
│   ├── Models/                      RevealCard、SeededRNG、收藏 / 笔记 / 浏览记录
│   ├── Stores/                      DailyCardStore（今天这张）、NotesStore、ShareManager、ThemeManager
│   ├── Views/
│   │   ├── Home/                    卡片正反面、翻面、笔记、分享面板
│   │   ├── Bible/                   整章经文
│   │   ├── Calendar/                日历、收藏与笔记列表
│   │   ├── Settings/                设置、隐私政策、资料来源与版权
│   │   ├── Onboarding/              语言选择 + 5 步引导
│   │   ├── Components/              按钮等小组件
│   │   └── SplashView.swift         启动动画
│   └── Resources/
│       ├── RevealCards_bilingual.json   314 张卡（中英经文 + 默想 + 行动）
│       ├── ChineseBible1919.json        66 卷 / 1,189 章 / 31,020 节
│       └── reveal_chime.caf             提醒提示音
├── VibeTests/                       单元测试：数据、配色、字号、法律边界
├── VibeUITests/                     界面测试：引导、翻面、日历、隐私页、截图
└── docs/                            上架素材：隐私政策、审核说明、截图、本文件
```

**一句话分层**：`Models`（数据长什么样）→ `Stores`（今天给什么、记了什么）→ `Design`（长什么样）→ `Views`（怎么用）→ `Resources`（内容）

**One line**: models say what the data is, stores decide what today means, design decides how it looks, views let you move through it, resources carry the text.

### 状态放在哪里 / Where state lives

- 三个全局对象：`DailyCardStore`（今天这张、语言、收藏）、`ThemeManager`（外观）、`ShareManager`（分享）
- 轻量偏好走 `@AppStorage`：提醒时间、字形、卡片文字颜色、自定义配色
- 收藏、笔记、浏览日期存本地 —— **没有账号、没有后端、没有云**

**No account, no backend, no cloud. Everything the app remembers lives on the phone.**

---

## 四、四个难关 / Four things that actually hurt

### 1. 经文能不能用 / Were we allowed to use the text

在线 API 给的是 **1989「新标点和合本」**，版权由联合圣经公会与香港圣经公会主张 —— 不能上架。
改用 **1919 官话和合本**（公有领域）：逐卷抓取、解析模板、清理 1,137 处残留标记，重建 **66 卷 / 1,189 章 / 31,020 节**，整本内置。

**The API served the 1989 revision, whose rights are held by the Bible societies. We rebuilt the 1919 public-domain edition instead — 31,020 verses, bundled offline.**

> **重点**：这不是「找个免费版本」，是「哪一版法律上站得住」。换对了版本，才敢上架。

### 2. 简体还是繁体 / Simplified or traditional

改字可能让「复制」变成「改编」，改编就要授权。做法：**逐字**转换（4,057 条单字表）、保留 1919 用字与标点、写一条**等长测试**——谁改一个词，测试立刻失败。

**Character-level conversion only, plus a test that fails the moment anyone edits a word — the legal line is enforced by code, not by a paragraph in a doc.**

> **重点**：法律不是写一份说明守住的，是让它变成一条会失败的测试。

### 3. 卡片长什么样 / What the card should look like

- 白字在浅色卡上只有 **1.18–1.43:1**，小标题几乎消失。试过阴影、局部压暗、整体压到 4.6:1、同色系深色字 —— 都不合适
- 最后：**给白字 2.2:1 的地板**，低于它的色阶按 6% 一步步压深，达标的完全不动（深色那组 8.85:1 原样）
- 正反面原来是两套机制：正面会被压缩缩得比默认还小，背面写死不动 → 合并成一套 `CardTypeScale`

**White type had nowhere to sit; we gave it a floor instead of repainting the design. And the two faces finally shared one type scale, so large system text no longer makes the front smaller than the back.**

> **重点**：设计不是一次定稿的。是做出来 → 真机上看 → 发现自己错了 → 改一版。

### 4. 过审 / Getting through review

- 隐私：无追踪、无收集数据，只声明 UserDefaults（CA92.1）
- **政策必须和代码一致**：英文整章联网、中文全本内置 —— 支持页原来写错，审核员一看就矛盾
- 版权声明写在 App 内：WEB 公有领域、1919 公有领域、明确声明不用 1989 版
- 中国大陆暂不销售（ICP 未办）

**Review isn't about asking nicely — it's making every public claim match the binary.**

> **重点**：审核不是求通过，是把每个声明都对回代码。

---

## 五、数字 / By the numbers

- **31,020** 节中文经文内置 / verses bundled
- **314** 张卡片，**46** 卷书 / cards across 46 books
- **13** 组渐变，**24** 个卡片名 / 13 gradients behind 24 names
- **4,057** 条繁简单字对照 / conversion pairs
- **96 : 96** 中英界面文案键 / localisation keys, fully paired
- **55** 个自动化测试 / automated tests
- **2** 次 TestFlight，**3** 个 build / uploads and builds
- **3.5** 周 / weeks

---

## 六、结尾 / Closing

**这不是「做了个 App」的故事。是发现经文不该那么用、设计在真机上读不出来、政策写的和代码不一样，然后一条一条改对的故事。**

**This isn't a story about building an app. It's about finding out the text wasn't ours to use, the design didn't read on a real phone, and the policy didn't match the code — then fixing each one.**
