# 个人 iOS 本地音乐播放器 · 技术方案 v2

> 目标：一款部署在**你自己 iPhone** 上的音乐播放器 —— 本地曲库播放功能齐全、界面精美、支持全网搜索与下载。
> 定位：**自用、侧载、不上架 App Store**，因此不受苹果审核约束，可以用 Sideload 方案长期续签。
> 文档日期：2026-09-04（v2 已根据设备与环境答复调整）

## 你的答复 → 方案调整

| 你的回答 | 对方案的影响 |
|---|---|
| **iPhone 14 Pro Max** | A16 + 6GB RAM，性能充裕；有灵动岛 → **Live Activity 可用**；支持 iOS 26 → **Liquid Glass 可用**；巨魔（TrollStore）基本无望，走 SideStore |
| **没有 Mac** | ⚠️ **最大阻塞，见第〇章**。方案已改为"云端构建 + SideStore 安装"，零成本起步 |
| **音源 A 和 B 都要** | 端侧 JS 引擎为主、自建 Docker 网关为副，共用同一套 `SourceProvider` 协议 |
| **合规不懂** | 见第〇章下方的大白话版说明，我给了默认档位，你不用纠结 |
| **边搜边下** | **核心场景**，M2 就把"搜索 → 试听 → 下载"闭环做出来，优先级高于本地曲库导入 |
| **几百首** | 数据层**改用 SwiftData**（GRDB+FTS5 是为万级曲库准备的，现在过度设计） |

---

## 〇、最大阻塞：你没有 Mac

这是硬约束：**Xcode 只能运行在 macOS 上**（苹果许可条款 + 技术上都如此），原生 iOS App 无法在 Windows 上编译。但这不等于项目做不成，只是**协作方式变了**：我在这台 Windows 上写代码，交给云端的 Mac 去编译打包，你在手机上安装。

### 三条路对比

| 方案 | 一次性成本 | 持续成本 | 迭代速度 | 你怎么装 App | 推荐度 |
|---|---|---|---|---|---|
| **A. GitHub Actions 云构建 + SideStore** | **¥0** | **¥0** | 慢（改一次 ≈ 8–15 分钟出包） | SideStore 导入 ipa | ★★★★ **起步首选** |
| **B. 买台二手 M1 Mac mini** | ¥1500–2200（8+256）<br>¥2700–2900（16+256） | ¥0 | 快（Xcode 实时预览） | 数据线直连 / SideStore | ★★★★★ 长期最优 |
| **C. 付费开发者账号 + TestFlight** | ¥688/年 | ¥688/年 | 慢（同 A） | TestFlight 点一下就更新，**OTA 自动推送** | ★★★★ 体验最好 |
| D. 云 Mac 租用 | ¥0 | 约 ¥150–300/月 | 中 | 远程桌面 | ★★★ 备选 |

### 我的建议：A 起步，UI 阶段再上 B

- **A 零成本、今天就能搭起来**。我先把工程骨架 + CI 流水线 + 打包流程全做好，你手机上先装上一个"能跑的骨架"再往下走。
- 到了 **UI 精调阶段（约占工作量 40%）**，A 的"改一次等 10 分钟"会很痛苦，那时再买台二手 Mac mini，效率立刻翻倍。
- **如果你完全不想折腾 → 直接 C**：花 ¥688 买开发者账号走 TestFlight，你在手机上点一下就更新，全程不碰电脑。账号持有者本人走 TestFlight 内部测试**不需要苹果审核**。

### A 方案的具体链路（关键事实已核实）

```
我（Windows）写代码 → push 到 GitHub 公开仓库
      ↓
GitHub Actions 在 macos-26（arm64）上跑 xcodebuild
      ↓   公开仓库的 macOS 构建分钟数不限量，零成本
产出 .ipa（ad-hoc 自签名 + 完整 entitlements）
      ↓
你去 Actions 页面下载 ipa（或我做成 Release 附件，手机上 Safari 直接下）
      ↓
iPhone 上 SideStore 导入 → 用你的免费 Apple ID 重签安装
      ↓
SideStore 每天自动续签，7 天限制自动破解，永久免电脑
```

已核实的事实：

- GitHub **公开仓库的 Actions 分钟数完全免费不限量**；私有仓库 Free 计划只有折合 200 分钟的 macOS 额度（macOS 按 10 倍扣配额）。**所以仓库必须设为公开。**
- GitHub 现有 `macos-26`（arm64，`macos-latest` 指向它）和 `macos-15` 镜像，预装 Xcode 26。
- SideStore 用免费 Apple ID 在**设备本地**完成签名与自动续签，不需要电脑常开。首次安装 SideStore 需要用你现在这台 Windows 跑一次 AltServer，之后永久免电脑。
- 免费 Apple ID 的证书最多同时挂 3 个 App（SideStore 自己占 1 个，剩 2 个）；配合 **LiveContainer** 可以突破这个数量限制。
- iPhone 14 Pro Max 若已升到 iOS 26，巨魔（TrollStore）基本无望 → 走 SideStore。

### A 方案的唯一技术坑：后台播放权限

不签名的 ipa 没有后台音频权限，一切后台就停。解决办法是构建时用一个 `Entitlements.plist` 做 ad-hoc 自签名，把 `UIBackgroundModes: audio` 等权限写进去，SideStore 重签时会保留。**这个我在工程里配好，你不用管。** M1 阶段的验收标准就是"锁屏后音乐还在响"。

---

### 合规，用大白话讲

| 情况 | 判定 | 我的处理 |
|---|---|---|
| 你自己买的、自己网盘里的、自己电脑导进去的歌 | ✅ 完全没问题 | 默认支持 |
| Jamendo、Free Music Archive、Internet Archive 这些 CC 授权/公有领域的音乐 | ✅ 完全没问题 | 默认内置 |
| 平台上本来就免费能听的歌 | ✅ 没问题 | 默认支持 |
| 平台要会员才能听的歌，通过第三方镜像接口下载 | ⚠️ 严格说侵犯版权 | **做成你自己导入的插件，App 不预置、不代维护** |

说句实在的：**个人自用、不传播、几百首的量，实务上不会有法律风险**。你真正会遇到的麻烦不是律师函，而是——**接口三天两头失效、隔几天就搜不到东西、得不停换音源**。所以我把"换音源"做成热插拔：源挂了，你导入一个新的就行，不用改代码、不用重新打包。

**底线：我不会写任何破解付费内容或绕过 DRM 的代码。** 这条没得商量。

---

## 一、GitHub 调研结果

### 1.1 直接相关的开源项目

| 项目 | Star | 技术栈 | 最近更新 | 协议 | 能借鉴什么 | 局限 |
|---|---|---|---|---|---|---|
| [kushalpandya/Petrichor](https://github.com/kushalpandya/Petrichor) | 1.6k | Swift / macOS | 2026-09-03 | **MIT** | **曲库与数据层范本**：`Core/Metadata`、`Core/Playback`、`LyricsLoader`、`ArtworkCache`、`LibrarySearch`、`Managers/Database`、`ScrobbleManager`、`RemoteCommandManager`、艺人信息解析、文件夹层级构建 | 仅 macOS，UI 层（AppKit/窗口/菜单栏）不可用；逻辑层多与 macOS API 耦合 |
| [CassetteLab/cassette](https://github.com/CassetteLab/cassette) | 106 | **Swift 6 + SwiftUI / iOS 26+** | 2026-07-26 | **MPL-2.0** | **最接近的当代原生 iOS 播放器范本**：Liquid Glass 设计语言（iOS 26）、后台播放+锁屏+控制中心+AirPlay、真离线下载、AudioStreaming 引擎（FLAC/MP3/AAC/WAV/Ogg）、持久化播放会话、歌词、队列管理、Widget、ListenBrainz scrobble、Keychain 存凭据 | 纯 Subsonic/OpenSubsonic 客户端，**没有本地文件曲库、没有全网搜索下载** |
| [lyswhut/lx-music-mobile](https://github.com/lyswhut/lx-music-mobile) | 18k | React Native | 2026-08-04 | Apache-2.0 | **功能定义与音源生态的行业标准**：多平台搜索/播放/下载、音质切换、歌单同步、自定义音源 | RN 实现，iOS 端 UI 与原生体验有差距；下载到 iOS 沙盒的能力受限 |
| [lyswhut/lx-music-desktop](https://github.com/lyswhut/lx-music-desktop) | 53k | Electron | 2026-08-25 | Apache-2.0 | 自定义音源（JS 脚本）的**完整运行时规范与接口定义** | 桌面端 |
| [pdone/lx-music-source](https://github.com/pdone/lx-music-source) | 8.4k | JS 音源脚本 | 持续 | 各异 | **现成的"全网搜索"音源**，社区长期维护 | 第三方镜像接口，稳定性/合规性有风险 |
| [Macrohard0001/lx-ikun-music-sources](https://github.com/Macrohard0001/lx-ikun-music-sources) | 2.3k | 音源合集 | 持续 | 各异 | 音源聚合集合（GDAPI/ChKSz 等） | 同上 |
| [pure-music/PureMusic](https://github.com/pure-music/PureMusic)（棉花音乐） | 588 | Kotlin / KMP | 2026-09-03 | 无声明 | **多源统一抽象**：本地文件 / 网盘 / Navidrome / Subsonic / Emby / Jellyfin / Plex | 非 Swift；无协议声明，**不可直接引用代码** |
| [ssalggnikool/Navic](https://github.com/ssalggnikool/Navic) | 975 | Kotlin / KMP | 2026-09-03 | **GPL-3.0** | Navidrome 客户端 UI 参考 | GPL 传染，**不建议 Swift 项目参考其代码** |
| [rasmuslos/AmpFin](https://github.com/rasmuslos/AmpFin) | 301 | Swift / SwiftData / SwiftUI | 已归档 | NOASSERTION | SwiftData 曲库建模参考 | 已归档、Jellyfin 专用、协议不明 |
| [youstanzr/YouTag](https://github.com/youstanzr/YouTag) | 343 | Swift / iOS | 2025-10 | GPLv3+商标条款 | 本地导入、标签体系、智能歌单思路 | UI 老旧（非 SwiftUI）；**GPL + 商标限制，不能改派** |
| [dimitris-c/AudioStreaming](https://github.com/dimitris-c/AudioStreaming) | 370 | Swift / AVAudioEngine | 活跃 | MIT | **现成的 AVAudioEngine 流播内核**（Cassette 用的就是它）：边下边播、缓存、FLAC 等格式 | 需评估 EQ/变速/无间隙的扩展成本 |
| [NCrusher74/SwiftTaggerID3](https://github.com/NCrusher74/SwiftTaggerID3) | 9 | Swift | 活跃 | MIT | 读写 MP3 ID3 标签 | 只覆盖 ID3，MP4/FLAC 需另配 |
| [jayasme/SpotlightLyrics](https://github.com/jayasme/SpotlightLyrics) | 87 | Swift | — | — | LRC 解析 | 功能单薄，自研更可控 |

### 1.2 闭源但形态已被验证的对手

**Xmusic**（iOS，SwiftUI，灵感来自 LX Music，2026 年已迭代到 1.2）
- 特性：导入音源（文件/链接）、搜索、下载（可选音质）、歌单与热榜、歌词封面、分享导出到本地、**CarPlay**、收藏。
- 分发方式：**签名或巨魔安装**，不走 App Store。
- 已知痛点（社区反馈）：**音源经常失效、需要持续维护**；证书签名下"从文件导入音源"会失败，只能用链接导入。

> 这直接证明了两件事：**(1) 这个形态在 iOS 上跑得通；(2) 音源维护是这类 App 的唯一长期成本**。我们的方案必须把"换音源"做成热插拔、无需改代码的能力。

### 1.3 三条关键结论

1. **没有** 一个"本地播放 + 全网搜下 + 精美原生 UI"三者兼备的开源 iOS 项目。市场空白是真实存在的。
2. **零件全都现成**：播放器骨架（Cassette）、曲库/元数据/歌词数据层（Petrichor）、全网搜索（lx 音源生态）、音频内核（AudioStreaming）。
3. **不要整包 fork**：Petrichor 是 macOS、Cassette 是服务端客户端、Navic/YouTag 是 GPL。整包 fork 会背上大量无关代码和协议包袱。**建议按"参考设计 + 重写实现"的方式复用**，协议上只 MIT/MPL 的问题最小（MPL-2.0 是文件级 copyleft，自用不分发基本无影响）。

---

## 二、合规边界（必须先讲清楚）

本方案**不涉及破解付费内容**。请按下面三条线区分，我会按你选择的档位实现：

| 档位 | 曲源 | 性质 | 建议 |
|---|---|---|---|
| 🟢 安全 | 你自己的本地文件、你的 NAS/Navidrome/Jellyfin/Emby/Plex、你的网盘私有资源、Bandcamp 已购、Internet Archive 公有领域现场、Jamendo / Free Music Archive（CC 授权） | 完全合法 | **默认实现，放心用** |
| 🟡 灰色 | 网易云/QQ音乐/酷狗/酷我/咪咕的**第三方镜像接口**、YouTube Music 抓取 | 多为对商业平台接口的逆向，多数平台 ToS 明确禁止；下载受版权保护的音乐在多数司法辖区构成侵权；且接口随时失效 | **做成可插拔插件，默认不内置**，你自己决定是否启用、风险自负 |
| 🔴 不可做 | 破解付费音质、绕过会员/DRM | 违法 | **明确不做** |

**我的建议**：App 内把搜索源做成"插件市场"式的管理界面，🟢 类源出厂内置；🟡 类源需要你自己导入（文件/URL），App 不预置、不分发、不代维护。这样既能满足"全网搜索下载"的诉求，又把责任和可变性隔离在插件层。

---

## 三、技术选型

| 层 | 选型 | 理由 |
|---|---|---|
| 语言 / UI | **Swift 6 + SwiftUI**，最小支持 **iOS 17**，Base SDK 用 Xcode 26 | iOS 26 起启用 Liquid Glass，低版本自动降级 Material；SwiftUI + async/await 是当代原生最快路径 |
| 音频内核 | **AVAudioEngine + AVAudioPlayerNode + AVAudioUnitEQ + AVAudioUnitTimePitch**；候选 `dimitris-c/AudioStreaming` | 原生支持 FLAC / ALAC / AAC / MP3 / WAV（iOS 11+ 支持 FLAC）；AVAudioEngine 才能同时做无间隙、EQ、变速、交叉淡入淡出 |
| 不支持格式 | APE / DSD / WMA | 原生无解码器，需自行编译解码器（FFmpeg/BASS），**P2 再评估**，初期明确不支持 |
| 数据库 | **SwiftData**（v2 已改，原为 GRDB+FTS5） | 你只有几百首，GRDB+FTS5 是给万级曲库准备的，属于过度设计。SwiftData 与 SwiftUI 深度集成、开发快。**但数据访问会抽象成协议，将来曲库涨到万级可平滑换 GRDB，业务代码不用改。** 建模参考 AmpFin |
| 网络 / 下载 | **URLSession**，下载走 **background session** + `UIBackgroundModes: audio, fetch` | 后台续下、断点续传、退 App 不断连 |
| 元数据 | AVFoundation 读 + **SwiftTaggerID3** 写 MP3 标签；MP4/FLAC 走 AVAsset 写入 | 读优先用系统，写标签用专用库 |
| 歌词 | 自研 LRC/逐字解析 + 内嵌歌词（ID3 SYLT/USLT、MP4 ©lyr）+ **LRClib** 公共 API | LRClib 是开源社区维护的合法歌词库 |
| 图片 | **Kingfisher / Nuke** + 封面取色（主色/渐变主题） | 二级缓存 + 动态主题是"界面精美"的关键 |
| 凭据 | **Keychain** | Cassette 同款做法 |
| 模块化 | 本地 **Swift Package** 分层：`App / Feature / Core / Shared` | 编译快、边界清、便于我分模块交付 |

### 为什么不做 Flutter / RN / KMP 混编
你要的是"界面精美 + 功能齐全"，这类 App 的深度体验全在原生细节上：锁屏/控制中心的 `MPRemoteCommandCenter`、CarPlay、灵动岛 Live Activity、Widget、`AVAudioEngine` 音频链、iOS 26 的 Liquid Glass。**跨平台方案在这些点上一律要写原生插件，等于两套成本**。所以：原生 Swift。

---

## 四、系统架构

```
┌──────────────────────────────────────────────────────────┐
│  表现层 (SwiftUI)                                         │
│  Library · Search · Player · Lyrics · Downloads · Settings │
│  MiniPlayer · Widgets · LiveActivity · CarPlay             │
└───────────────────────────┬──────────────────────────────┘
                            │  @Observable ViewModel
┌───────────────────────────▼──────────────────────────────┐
│  领域层 (Domain)                                          │
│  PlayerService  LibraryService  SearchService             │
│  DownloadService  LyricsService  MetadataService          │
│  PlaylistService  ScrobbleService  SyncService            │
└───────────────────────────┬──────────────────────────────┘
                            │  协议 (Protocol) 依赖倒置
┌───────────────────────────▼──────────────────────────────┐
│  基础设施层 (Infra)                                        │
│  AudioEngine   SwiftData   FileStore   Network/URLSession │
│  ArtworkCache  Keychain    CryptoBridge  JSEngine         │
└───────────────────────────┬──────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────┐
│  曲源层 (SourceProvider 统一协议)                          │
│  ┌───────────┬───────────┬───────────┬─────────────────┐  │
│  │ LocalFile │ Subsonic/ │ WebDAV /  │ 音源插件         │  │
│  │ (沙盒/文件 │ Navidrome │ 网盘      │ (JS 引擎 /      │  │
│  │   App导入) │ Jellyfin  │           │  自建网关)      │  │
│  └───────────┴───────────┴───────────┴─────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

核心设计原则：**播放器只认 `Track`，不认"这首歌从哪来"**。所有曲源统一实现 `SourceProvider` 协议（`search / resolve / fetch / lyrics / artwork`），新增一个源 = 新增一个实现，播放器零改动。

### 4.1 全网搜索下载：两条技术路线（重点决策项）

**路线 A：端侧 JS 音源引擎（推荐做主线）**
- 用 iOS 自带的 **JavaScriptCore** 在 App 内跑洛雪格式的音源脚本，直接复用 `lx-music-source` 生态（8.4k star，社区持续维护）。
- 需要我写一个兼容层把浏览器 API 桥接到原生：
  - `fetch / XMLHttpRequest` → `URLSession`
  - `crypto`（AES / MD5 / RSA / HMAC）→ `CryptoKit` / `CommonCrypto`
  - `Buffer / atob / btoa` → `Data`
  - `console / localStorage` → 日志 / UserDefaults
- 优点：**零服务器、换源热插拔、生态成熟**。
- 风险：部分音源用了难兼容的 JS 特性；酷我等平台的加密音频（如 QMC / KGM）需要额外解密模块。

**路线 B：自建音源网关（推荐做副线/兜底）**
- 在家里 NAS / 云主机跑一个 Docker：Node 的 `lx-music-api-server` 或 `NeteaseCloudMusicApi` / `meting`，可选挂 `yt-dlp`。
- iOS 端只做 REST 客户端 + 下载。
- 优点：**极稳定、音源更新不用重签 App**、可以做缓存和多端同步。
- 缺点：多一台服务器；出门在外要穿透/公网。

**我的建议：A 为主、B 为可选开关。** 两条路共用同一个 `SourceProvider` 协议，UI 完全一致。

---

## 五、功能清单（按优先级）

### P0 · 核心（第一个可用版本）
- 播放：播放/暂停/上下曲/进度拖拽、后台播放、锁屏 + 控制中心、`MPNowPlayingInfoCenter` 封面与信息、耳机线控与蓝牙、播放队列、随机/单曲循环/列表循环、记忆上次播放位置
- 曲库：本地文件导入（Files App / AirDrop / 分享面板 / iTunes 文件共享）、全盘扫描、按歌曲/专辑/艺术家/文件夹浏览、搜索、收藏
- 下载：单曲/批量下载、音质选择、后台下载 + 断点续传、下载完成后自动写入元数据与封面、自动匹配歌词
- 搜索：聚合全网搜索（可启用插件）、结果聚合去重、按音质/来源筛选
- 界面：Mini Player、Now Playing 全屏页（封面取色动态主题 + 模糊背景）、基础歌词页

### P1 · 体验
- 无间隙播放（gapless）、交叉淡入淡出、**10 段 EQ + 预设**、变速不变调、音量增益、睡眠定时器
- 歌词：外置 `.lrc` 自动关联、内嵌歌词、逐行高亮滚动、翻译/双语、手动偏移校正
- 曲库：标签编辑（标题/艺术家/专辑/年份/流派/封面）、智能歌单（按标签/年份/播放次数/评分/时长动态筛选）、播放次数与"最近播放"、批量操作、m3u 导入导出
- 界面：频谱/波形可视化、流畅转场（列表→播放页共享元素动画）、iPad 与横屏适配、桌面小组件、灵动岛 Live Activity
- 系统：**CarPlay**、AirPlay、Siri 快捷指令、Spotlight 索引曲库

### P2 · 进阶
- Wi-Fi 传歌（App 内起 HTTP 服务，电脑浏览器拖拽上传）
- 网盘 / WebDAV / Navidrome / Jellyfin / Emby / Plex 连接器
- Last.fm / ListenBrainz 播报（scrobble）
- 网盘与本地曲库双向同步、歌单云备份、iCloud 备份
- 年度听歌报告（参考 Cassette Wrapped）
- APE / DSD 支持（外接解码器）

---

## 六、UI 设计方向

**设计语言**：iOS 26 Liquid Glass（低版本降级 Material），整体走"封面驱动 + 沉浸式"。

| 页面 | 设计要点 |
|---|---|
| 首屏「曲库」 | 顶部大尺寸"最近播放"横向卡片流，下方分段（歌曲/专辑/艺术家/歌单/文件夹），全局搜索置于顶部 |
| 「搜索」 | 搜索框 + 历史 + 热榜；聚合结果按来源分组，每条右侧直接下载按钮；长按下拉选音质 |
| 「播放页」 | 全屏毛玻璃背景取封面主色渐变；大封面（可上滑看歌词）；旋转唱片 / 频谱二选一；底部控制区 + 队列入口 |
| 「歌词页」 | 逐行高亮 + 当前行放大，支持拖动定位、翻译行、字号与对齐设置 |
| 「下载管理」 | 进行中/已完成分组，断点续传进度、失败重试、存储占用统计 |
| Mini Player | 常驻底部，左滑切歌、点击展开、进度条内嵌 |
| 主题 | 从封面提取主色生成动态主题；提供深色/浅色/自动 + 3 套强调色；支持纯黑模式 |

**"精美"具体落到这几件事**：取色动态主题、共享元素转场、毛玻璃层次、弹簧动画参数统一、封面模糊背景、频谱可视化、统一的圆角/间距/字号体系。这些我会先出一份高保真设计稿再写代码。

---

## 七、构建与安装（自签长期化）

因为不上架，签名是绕不开的一环：

| 方案 | 有效期 | 需要电脑 | 说明 |
|---|---|---|---|
| Xcode 免费 Apple ID | 7 天 | 是（首次） | 最简单，但**每 7 天要重签一次**，且免费账号有 App ID 数量限制 |
| **SideStore** | 7 天自动续 | 否 | 设备内自签 + 本地网络自动刷新，**个人长期用首选** |
| AltStore Classic | 7 天自动续 | 是（AltServer 常开） | 依赖电脑 |
| TrollStore / 巨魔 | 永久 | 否 | 仅特定 iOS 版本可用，**需看你的系统版本** |
| 付费开发者账号（¥688/年） | 1 年 | 否 | 最省心，但要钱，且需过审才能上架（TestFlight 分发也要审） |

**推荐：SideStore**（免费、免电脑、自动续签）。建议单注册一个 Apple ID 专用于侧载，避免主账号风险。

---

## 八、里程碑与工作量

| 里程碑 | 内容 | 预估 |
|---|---|---|
按"边搜边下是核心场景"重排了顺序：

| 里程碑 | 内容 | 验收标准 | 预估 |
|---|---|---|---|
| **M0 环境与流水线** | 建公开仓库、Swift Package 分层、GitHub Actions 构建、entitlements 自签名、SideStore 装通 | 你手机上能打开一个空白 App，**锁屏后音乐还在响** | 0.5–1 天 |
| **M1 播放内核** | AVAudioEngine 音频链、后台播放、锁屏/控制中心、队列、AirPlay | 能播本地几首歌，锁屏可控 | 2–3 天 |
| **M2 搜索→试听→下载**（提前） | `SourceProvider` 协议、端侧 JS 音源引擎、聚合搜索、试听、下载管理、后台断点续传、自动写元数据+封面+歌词 | 搜一首歌 → 点播放 → 下载 → 曲库里出现带封面的歌 | 5–7 天 |
| **M3 曲库与导入** | SwiftData 建模、扫描、标签编辑、收藏、文件导入（Files/AirDrop/分享面板） | 几百首歌能顺畅浏览检索 | 3–4 天 |
| **M4 播放页 UI** | 播放页、Mini Player、歌词页、封面取色动态主题、转场动画 | 界面达到"精美"标准 | 4–5 天 |
| **M5 打磨** | EQ、无间隙、频谱可视化、Widget、灵动岛 Live Activity、CarPlay | 日常使用无短板 | 4–6 天 |
| **M6 长期维护** | 自建网关（路线 B）、音源热更新、备份、性能优化 | 源挂了能一键换 | 持续 |

**合计约 19–26 个人天。** 前 M0–M2 我可以在你这台 Windows 上完成绝大部分，只在你手机装包时才需要你动手。

> ⚠️ **M4 是分水岭**：UI 精调需要高频"改一眼看一眼"，用 A 方案一轮 10 分钟会很煎熬。**建议 M4 之前把二手 Mac 的问题解决了**，或者干脆一开始选 C 方案走 TestFlight。

---

## 九、主要风险

| 风险 | 等级 | 应对 |
|---|---|---|
| 音源接口失效（Xmusic 社区的头号痛点） | 高 | 插件热插拔 + 多源自动降级 + 一键导入新源；不把源硬编码进 App |
| 7 天签名过期 | 中 | SideStore 自动续签；同时我会在工程里写好一键重签脚本 |
| AVAudioEngine 无间隙播放 + EQ 联调 | 中 | 先用 AudioStreaming 库验证，不行再自研调度 |
| 加密音频格式（QMC / KGM / NCM） | 中 | 独立解密模块，做成可选插件，失效不影响主流程 |
| 大曲库（>1 万首）内存与滚动性能 | 中 | FTS5 分页查询、图片三级缓存、`LazyVStack` + 封面尺寸限制 |
| iOS 版本碎片（17 / 18 / 26 / 27） | 低 | 最低 iOS 17，Liquid Glass 只在 26+ 启用，其余降级 |
| 合规 | — | 见第二节，插件隔离、App 不预置灰色源 |

> 补充：iOS 27 预计 9 月中旬发布。建议**等正式版推送后再升级系统**，开发期先用当前稳定版，避免 SDK 与真机调试的不必要麻烦。

---

## 十、下一步：你要做的三件事

在我把 M0 流水线搭好之前，你先准备这三样，**全程免费**：

1. **注册一个专用 Apple ID**（建议新号，别用主号，避免风控）。这是给 SideStore 签名用的。
2. **注册 GitHub 账号 + 建一个公开仓库**（必须 Public，Public 仓库的构建才不限量）。仓库我建议起名 `echomusic` 之类，建好把地址给我。
3. **装 SideStore**：在你这台 Windows 上装 AltServer（Windows 版），用数据线把 iPhone 连一次，把 SideStore 装上。**这一步做完，以后永久不用再连电脑。**

### 还有一件事要你确认

**你的 iPhone 现在是什么 iOS 版本？**（设置 → 通用 → 关于本机 → 软件版本）

- 如果是 **iOS 26.x** → 走 SideStore，Liquid Glass 界面可用，巨魔不可用。
- 如果是 **iOS 16.x / 17.0** → 有极小概率能用 TrollStore 永久签名，那体验会好一大截。
- 不论哪个版本，建议**先别急着升 iOS 27**（9 月中旬发布），等正式版铺开再升，避免开发期踩系统坑。

---

## 附：v2 变更记录

| 项目 | v1 | v2 | 原因 |
|---|---|---|---|
| 数据库 | GRDB + FTS5 | **SwiftData**（访问层抽象成协议，可平滑换回） | 几百首规模，FTS5 过度设计 |
| 构建方式 | 本地 Xcode | **GitHub Actions（macos-26）+ SideStore** | 没有 Mac |
| 里程碑顺序 | 曲库优先 | **搜索下载优先（M2）** | 核心场景是"边搜边下" |
| 数据来源 | — | 数据库改用 SwiftData，新增 Live Activity / LiveContainer 说明 | 设备与规模确定 |
| 合规 | 表格分档 | 增加大白话版说明 + 默认档位 | 用户表示不了解 |

---

## 附：参考仓库清单

```
# 播放器架构范本（重点读）
https://github.com/CassetteLab/cassette              Swift6/SwiftUI, iOS26+, MPL-2.0
https://github.com/kushalpandya/Petrichor            Swift/macOS, MIT —— 数据层范本
https://github.com/dimitris-c/AudioStreaming         AVAudioEngine 流播内核, MIT

# 音源生态
https://github.com/pdone/lx-music-source             8.4k 音源
https://github.com/Macrohard0001/lx-ikun-music-sources
https://github.com/lyswhut/lx-music-mobile           功能定义参考
https://github.com/MeoProject/lx-music-api-server    自建网关参考

# 多源抽象 / 客户端参考
https://github.com/pure-music/PureMusic              多源统一抽象（无协议，只看思路）
https://github.com/rasmuslos/AmpFin                  SwiftData 建模（已归档）
https://github.com/youstanzr/YouTag                  本地导入与标签（GPL，只看思路）

# 依赖
https://github.com/NCrusher74/SwiftTaggerID3         ID3 读写, MIT
https://github.com/jayasme/SpotlightLyrics           LRC 解析
```
