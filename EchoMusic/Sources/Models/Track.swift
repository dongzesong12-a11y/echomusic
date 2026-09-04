import Foundation

/// 领域模型：播放器只认 Track，不认"歌从哪来"。
/// 所有曲源（本地文件 / 音源插件 / 自建网关）统一产出 Track。
/// M3 会把它升级为 SwiftData @Model；此处先用轻量 struct 保证 M0 可编译。
struct Track: Identifiable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var album: String

    init(id: UUID = UUID(), title: String, artist: String, album: String = "") {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
    }
}
