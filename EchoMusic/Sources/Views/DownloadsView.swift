import SwiftUI

struct DownloadsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("下载")
                    .font(.largeTitle.bold())
                Text("M1 播放内核已接")
                    .foregroundStyle(.secondary)
                Text("M2 接入后台断点续传下载管理")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("下载")
        }
    }
}
