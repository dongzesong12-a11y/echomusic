import Foundation
import SwiftUI

/// 领域模型：播放器只认 Track，不认"歌从哪来"。
/// 所有曲源（本地文件 / 音源插件 / 自建网关）统一产出 Track。
/// M3 会把它升级为 SwiftData @Model；此处先用轻量 struct 保证 M0/M1 可编译。
struct Track: Identifiable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var album: String
    /// 播放源。本地文件用 fileURL，网络/音源插件用远程 URL。M3 落库后由访问层填充。
    var sourceURL: URL?
    /// 时长（秒），可空；播放中由引擎回填。
    var duration: TimeInterval?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String = "",
        sourceURL: URL? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.sourceURL = sourceURL
        self.duration = duration
    }
}

// MARK: - 示例曲库（M1 用于真机验证出声；SoundHelix 为免版权演示曲）
extension Track {
    static var demoLibrary: [Track] {
        let base = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-"
        return (1...6).map { i in
            Track(
                title: "示例曲目 \(i)",
                artist: "Echo Demo",
                album: "Demo Album",
                sourceURL: URL(string: "\(base)\(i).mp3")
            )
        }
    }

    /// 由标题派生一组主题色，呼应原型的"按曲风/封面取色动态主题"。
    var themeColors: [Color] {
        let h = CGFloat(abs(title.hashValue) % 360) / 360
        let h2 = (h + 0.11).truncatingRemainder(dividingBy: 1)
        return [
            Color(hue: h, saturation: 0.62, brightness: 0.92),
            Color(hue: h2, saturation: 0.70, brightness: 0.66),
        ]
    }
}
