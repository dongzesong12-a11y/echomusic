import SwiftUI

struct SearchView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("搜索")
                    .font(.largeTitle.bold())
                Text("M0 骨架已装通")
                    .foregroundStyle(.secondary)
                Text("M2 接入 SourceProvider 聚合搜索")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("搜索")
        }
    }
}
