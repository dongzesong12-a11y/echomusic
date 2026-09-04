import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var player: PlayerService

    var body: some View {
        NavigationStack {
            List {
                Section("关于") {
                    LabeledContent("名称", value: "Echo")
                    LabeledContent("版本", value: "0.1.0")
                    LabeledContent("构建", value: "M0 骨架")
                }
                Section("播放状态") {
                    LabeledContent("当前曲目", value: player.currentTitle)
                    LabeledContent("播放中", value: player.isPlaying ? "是" : "否")
                }
            }
            .navigationTitle("设置")
        }
    }
}
