import Foundation
import SwiftData

/// M3：曲库持久化模型（SwiftData）。
/// 之前 Track 是轻量 struct（M0/M1 保证可编译），这里把它落库。
/// 播放器仍只认 Track；StoredTrack 提供 `track` 转换，访问层与引擎解耦。
@Model
final class StoredTrack {
    var id: UUID
    var title: String
    var artist: String
    var album: String
    var sourceURLString: String?
    var duration: Double?
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String = "",
        sourceURL: URL? = nil,
        duration: TimeInterval? = nil,
        dateAdded: Date = .now
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.sourceURLString = sourceURL?.absoluteString
        self.duration = duration
        self.dateAdded = dateAdded
    }

    var track: Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            sourceURL: sourceURLString.flatMap { URL(string: $0) },
            duration: duration
        )
    }
}
