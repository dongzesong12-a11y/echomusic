import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var player: PlayerService

    var body: some View {
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
    }
}
