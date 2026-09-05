import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var player: PlayerService

    var body: some View {
        NavigationStack {
            List {
                Section("关于") {
                    LabeledContent("名称", value: "Echo")
                    LabeledContent("版本", value: "0.1.0")
                    LabeledContent("构建", value: "M1 播放内核")
                }

                Section("播放状态") {
                    LabeledContent("当前曲目", value: player.currentTrack?.title ?? "—")
                    LabeledContent("艺术家", value: player.currentTrack?.artist ?? "—")
                    LabeledContent("播放中", value: player.isPlaying ? "是" : "否")
                    LabeledContent("队列长度", value: "\(player.queue.count)")
                }

                Section("播放设置") {
                    Toggle("随机播放", isOn: Binding(get: { player.shuffle },
                                                    set: { _ in player.toggleShuffle() }))
                    HStack {
                        Text("循环模式")
                        Spacer()
                        Button(player.repeatMode.label) {
                            player.cycleRepeat()
                        }
                        .foregroundStyle(.accentColor)
                    }
                }

                Section("音频引擎") {
                    LabeledContent("引擎", value: "AVPlayer（M3 可换 AVAudioEngine）")
                    LabeledContent("后台音频", value: "已开启 (UIBackgroundModes: audio)")
                }
            }
            .navigationTitle("设置")
        }
    }
}
