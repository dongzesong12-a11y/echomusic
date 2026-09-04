import SwiftUI

/// 播放内核占位（M0）。
/// M1 会在这里接 AVAudioEngine + AVAudioPlayerNode + AVAudioUnitEQ，
/// 并实现后台播放 / 锁屏与控制中心 / 队列 / AirPlay。
/// 现在只是可观测的状态容器，让四个 Tab 能共享同一份播放状态。
@MainActor
final class PlayerService: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTitle: String = "—"
    @Published var currentArtist: String = "—"
}
