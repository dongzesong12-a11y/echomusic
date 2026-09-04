import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("曲库")
                    .font(.largeTitle.bold())
                Text("M0 骨架已装通")
                    .foregroundStyle(.secondary)
                Text("M3 接入 SwiftData 曲库与导入")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("曲库")
        }
    }
}
