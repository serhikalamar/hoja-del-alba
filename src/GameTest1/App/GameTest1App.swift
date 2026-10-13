import SwiftUI

@main
struct GameTest1App: App {
    @State private var store = GameStore()
    /// Cuenta y guardado en la nube (sin configuración de Supabase, no hace nada).
    @State private var account = AccountManager()
    /// Ajustes en vivo publicados desde el panel de administración (sin configuración de Supabase, no hace nada).
    @State private var remoteConfig = RemoteConfig()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(account)
                .environment(remoteConfig)
                .onAppear {
                    remoteConfig.attach(to: store)
                    account.attach(to: store)
                }
            #if DEBUG
                .onAppear { DebugLaunch.apply(to: store) }
            #endif
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
            if phase == .active {
                account.scheduleSync(after: 1)
                remoteConfig.appBecameActive()
            }
        }
    }
}

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch store.screen {
            case .town:
                if let explore = store.explore {
                    ExploreView(session: explore)
                        .id(ObjectIdentifier(explore))
                }
            case .battle:
                if let battle = store.battle {
                    BattleView(session: battle)
                        .id(ObjectIdentifier(battle))
                }
            case .characterSelect:
                CharacterSelectView()
            case .characterCreate:
                CharacterCreateView()
            }
        }
    }
}
