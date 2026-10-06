import SwiftUI

@main
struct GameTest1App: App {
    @State private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
            #if os(iOS)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
            #else
                .frame(minWidth: 960, minHeight: 440)
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 1180, height: 560)
        #endif
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.appWentToBackground() }
        }
    }
}

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch store.screen {
            case .menu:
                MainMenuView()
            case .worldMap:
                WorldMapView()
            case .battle:
                if let battle = store.battle {
                    BattleView(session: battle)
                        .id(ObjectIdentifier(battle))
                }
            case .forge:
                RitualForgeView(showsBackButton: true)
            case .inventory:
                ScreenFrame(title: "INVENTARIO") { InventoryView() }
            case .race:
                RaceSelectView()
            }
        }
    }
}
