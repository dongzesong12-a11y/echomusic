import SwiftUI

/// 底部迷你播放条：悬浮在 Tab Bar 之上，点击展开全屏播放页。
struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlayerService
    @Binding var showNowPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(colors: player.currentTrack?.themeColors ?? [Color.accentColor, Color.accentColor.opacity(0.5)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 42, height: 42)
                .shadow(radius: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentTrack?.title ?? "")
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(player.currentTrack?.artist ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                player.togglePlay()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
            }
            .contentShape(Rectangle())

            Button {
                player.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
            }
            .contentShape(Rectangle())
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
        .padding(.horizontal, 10)
        .onTapGesture { showNowPlaying = true }
    }
}
