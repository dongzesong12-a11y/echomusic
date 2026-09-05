import SwiftUI
import AVFAudio
import SwiftData

@main
struct EchoMusicApp: App {
    @StateObject private var player = PlayerService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(player)
                .modelContainer(for: StoredTrack.self)
                .task {
                    configureAudioSession()
                }
        }
    }

    /// 后台播放的前提：把 AVAudioSession 设为 .playback。
    /// 真正"锁屏后音乐还在响"由 M1 的 AVAudioEngine 播放内核兑现，
    /// 这里先把 session 配好、并把后台音频权限（Info.plist 的 UIBackgroundModes=audio）激活。
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession 配置失败: \(error.localizedDescription)")
        }
    }
}
