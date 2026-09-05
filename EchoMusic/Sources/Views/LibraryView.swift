import SwiftUI
import SwiftData

struct LibraryView: View {
    @EnvironmentObject private var player: PlayerService
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredTrack.dateAdded, order: .reverse) private var stored: [StoredTrack]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(stored) { s in
                        Button {
                            play(s)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(colors: s.track.themeColors,
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title).font(.body.weight(.medium))
                                    Text(s.artist).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if player.hasCurrent, player.currentTrack?.id == s.id {
                                    Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("曲库（SwiftData 持久化，M3）")
                }
            }
            .navigationTitle("曲库")
            .overlay {
                if stored.isEmpty {
                    ContentUnavailableView("曲库为空", systemImage: "music.note.house.fill",
                                           description: Text("首次启动已自动写入示例曲；M3 将支持从文件导入"))
                }
            }
            .task { seedIfEmpty() }
        }
    }

    private func play(_ s: StoredTrack) {
        let tracks = stored.map { $0.track }
        if let idx = tracks.firstIndex(where: { $0.id == s.id }) {
            player.playQueue(tracks, startAt: idx)
        }
    }

    private func seedIfEmpty() {
        guard stored.isEmpty else { return }
        for t in Track.demoLibrary {
            modelContext.insert(
                StoredTrack(title: t.title, artist: t.artist, album: t.album,
                            sourceURL: t.sourceURL, duration: t.duration)
            )
        }
        try? modelContext.save()
    }
}
