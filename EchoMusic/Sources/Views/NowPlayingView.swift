import SwiftUI

/// 全屏播放页：封面（取色主题）、标题、进度、频谱占位、传输控制。
/// 频谱目前是纯视觉占位（动画柱），M3+ 接 AVAudioEngine 后换成真实 FFT。
struct NowPlayingView: View {
    @EnvironmentObject private var player: PlayerService
    @Environment(\.dismiss) private var dismiss
    let track: Track

    @State private var spectrum: [CGFloat] = (0..<40).map { _ in CGFloat.random(in: 0.2...1) }

    private var timeFormatter: DateComponentsFormatter {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .font(.title3.bold())
                        .padding(10)
                }
                Spacer()
                Text("正在播放")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 6)

            Spacer(minLength: 12)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(colors: track.themeColors,
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(maxWidth: .infinity, maxHeight: 320)
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
                .overlay(alignment: .bottomLeading) {
                    Text(track.title.prefix(1).uppercased())
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.22))
                        .padding(24)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.title.bold())
                    .lineLimit(1)
                Text(track.artist)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)

            // 进度
            Slider(value: Binding(get: { player.currentTime },
                                  set: { player.seek(to: $0) }),
                   in: 0...max(player.duration, 1),
                   label: { EmptyView() })
                .tint(.accentColor)
                .padding(.top, 14)

            HStack {
                Text(timeFormatter.string(from: player.currentTime) ?? "0:00")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timeFormatter.string(from: player.duration) ?? "0:00")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            // 频谱占位（动画）
            SpectrumView(bars: spectrum)
                .frame(height: 56)
                .padding(.vertical, 14)
                .onReceive(Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()) { _ in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        spectrum = spectrum.map { _ in CGFloat.random(in: player.isPlaying ? 0.2...1 : 0.08...0.22) }
                    }
                }

            // 传输控制
            HStack(spacing: 0) {
                Spacer()
                Button { player.toggleShuffle() } label: {
                    Image(systemName: "shuffle")
                        .font(.title3)
                        .foregroundStyle(player.shuffle ? .accentColor : .primary)
                }
                Spacer()
                Button { player.previous() } label: {
                    Image(systemName: "backward.fill").font(.title)
                }
                Spacer()
                Button { player.togglePlay() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.accentColor)
                }
                Spacer()
                Button { player.next() } label: {
                    Image(systemName: "forward.fill").font(.title)
                }
                Spacer()
                Button { player.cycleRepeat() } label: {
                    Image(systemName: repeatModeIcon)
                        .font(.title3)
                        .foregroundStyle(player.repeatMode == .off ? .primary : .accentColor)
                }
                Spacer()
            }
            .padding(.bottom, 24)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .background(
            LinearGradient(colors: track.themeColors.map { $0.opacity(0.18) } + [Color.clear],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private var repeatModeIcon: String { player.repeatMode.systemImage }
}

/// 频谱占位条
struct SpectrumView: View {
    let bars: [CGFloat]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, h in
                Capsule()
                    .fill(Color.accentColor.opacity(0.8))
                    .frame(width: 3, height: max(4, h * 52))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
