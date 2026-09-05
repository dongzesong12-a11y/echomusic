import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI

/// 播放模式
enum RepeatMode: Int, CaseIterable, Identifiable {
    case off, all, one
    var id: Int { rawValue }
    var systemImage: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
    var label: String {
        switch self {
        case .off: return "列表循环关"
        case .all: return "列表循环"
        case .one: return "单曲循环"
        }
    }
    func next() -> RepeatMode { RepeatMode.allCases[(RepeatMode.allCases.firstIndex(of: self)! + 1) % RepeatMode.allCases.count] }
}

/// M1 播放内核。
/// 用 AVPlayer 承载队列播放（流媒体/本地文件通吃，且与锁屏、控制中心集成顺滑）。
/// 引擎层对上层只暴露 Track 与少量命令；M3+ 可在此把 AVPlayer 换成
/// AVAudioEngine + AVAudioPlayerNode + AVAudioUnitEQ 以支持 FLAC/ALAC 与实时频谱。
@MainActor
final class PlayerService: ObservableObject {
    // MARK: - 可观测状态
    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0
    @Published var currentTrack: Track? = nil
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var shuffle: Bool = false
    @Published var repeatMode: RepeatMode = .off

    // MARK: - 引擎
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var remoteCommandsReady = false

    // MARK: - 队列控制
    func play(_ track: Track) { playQueue([track], startAt: 0) }

    func playQueue(_ tracks: [Track], startAt index: Int = 0) {
        guard !tracks.isEmpty else { return }
        queue = tracks
        currentIndex = min(max(index, 0), tracks.count - 1)
        ensurePlayer()
        ensureRemoteCommands()
        loadCurrentAndPlay()
    }

    func togglePlay() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlaying()
    }

    func play() { guard player != nil else { return }; player?.play(); isPlaying = true; updateNowPlaying() }
    func pause() { player?.pause(); isPlaying = false; updateNowPlaying() }

    func next() {
        guard !queue.isEmpty else { return }
        if repeatMode == .one { seek(to: 0); return }
        if shuffle {
            currentIndex = Int.random(in: 0..<queue.count)
        } else if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else {
            // 到队尾
            if repeatMode == .all { currentIndex = 0 } else { player?.pause(); isPlaying = false; return }
        }
        loadCurrentAndPlay()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 { seek(to: 0); return }
        if shuffle {
            currentIndex = Int.random(in: 0..<queue.count)
        } else if currentIndex > 0 {
            currentIndex -= 1
        } else {
            currentIndex = queue.count - 1
        }
        loadCurrentAndPlay()
    }

    func seek(to time: TimeInterval) {
        let cm = CMTime(seconds: max(0, time), preferredTimescale: 600)
        player?.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = max(0, time)
        updateNowPlaying()
    }

    func toggleShuffle() { shuffle.toggle() }
    func cycleRepeat() { repeatMode = repeatMode.next() }

    var hasCurrent: Bool { currentTrack != nil }

    // MARK: - 内部
    private func ensurePlayer() {
        if player == nil {
            player = AVPlayer()
            player?.automaticallyWaitsToMinimizeStalling = true
            let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
            timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
                // 只把 Double 带进 Task，避免 CMTime 的 Sendable 推断问题（Swift 6 严格并发）
                let seconds = t.seconds
                Task { @MainActor in self?.handleTime(seconds: seconds) }
            }
        }
    }

    private func loadCurrentAndPlay() {
        guard queue.indices.contains(currentIndex) else { return }
        let track = queue[currentIndex]
        currentTrack = track
        currentTime = 0
        duration = track.duration ?? 0
        guard let url = track.sourceURL else {
            isPlaying = false
            return
        }
        let item = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: item)
        player?.play()
        isPlaying = true
        updateNowPlaying()
    }

    private func handleTime(seconds: Double) {
        currentTime = seconds
        if let d = player?.currentItem?.duration, d.isValid, d.seconds.isFinite, d.seconds > 0 {
            duration = d.seconds
        }
        // 自然结束 -> 自动下一首
        if duration > 1, seconds >= duration - 0.4 {
            next()
        }
        updateNowPlayingElapsed()
    }

    // MARK: - 锁屏 / 控制中心
    private func ensureRemoteCommands() {
        guard !remoteCommandsReady else { return }
        remoteCommandsReady = true
        let rc = MPRemoteCommandCenter.shared()
        rc.playCommand.addTarget { [weak self] _ in Task { @MainActor in self?.play() }; return .success }
        rc.pauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.pause() }; return .success }
        rc.togglePlayPauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.togglePlay() }; return .success }
        rc.nextTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.next() }; return .success }
        rc.previousTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.previous() }; return .success }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = currentTrack?.title ?? ""
        info[MPMediaItemPropertyArtist] = currentTrack?.artist ?? ""
        info[MPMediaItemPropertyAlbumTitle] = currentTrack?.album ?? ""
        if duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingElapsed() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
