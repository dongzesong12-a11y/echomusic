import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var player: PlayerService
    @State private var showNowPlaying: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                LibraryView()
                    .tabItem { Label("曲库", systemImage: "music.note.house.fill") }
                SearchView()
                    .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                DownloadsView()
                    .tabItem { Label("下载", systemImage: "arrow.down.circle.fill") }
                SettingsView()
                    .tabItem { Label("设置", systemImage: "gearshape.fill") }
            }

            if player.hasCurrent {
                MiniPlayerView(showNowPlaying: $showNowPlaying)
                    .padding(.bottom, 56)
            }
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            if let track = player.currentTrack {
                NowPlayingView(track: track)
                    .environmentObject(player)
            }
        }
    }
}
