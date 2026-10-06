import GameCore
import SpriteKit
import SwiftUI

/// Pantalla de exploración del pueblo.
struct ExploreView: View {
    @Environment(GameStore.self) private var store
    let session: ExploreSession
    @State private var showingInventory = false
    #if os(macOS)
    @State private var keyboard = KeyboardMovement()
    #endif

    var body: some View {
        ZStack {
            SpriteView(scene: session.scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            #if os(iOS)
            if session.overlay == .none {
                JoystickArea { session.joystick = $0 }
                    .ignoresSafeArea()
            }
            #endif

            VStack(spacing: 8) {
                ExploreHUD(session: session)
                if let toast = session.toast {
                    Text(toast)
                        .font(Theme.font(13, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .overlay(Rectangle().strokeBorder(Theme.gold, lineWidth: 2))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .animation(.easeOut(duration: 0.2), value: session.toast)

            overlay
        }
        #if os(macOS)
        .onAppear {
            let session = self.session
            keyboard.onChange = { [weak session] in session?.joystick = $0 }
            keyboard.onEscape = { [weak session] in
                guard let session else { return }
                switch session.overlay {
                case .none: session.pause()
                case .paused: session.resume()
                case .smithy: session.closeSmithy()
                default: break
                }
            }
            keyboard.onAction = { [weak session] in
                if session?.overlay == .dialog { session?.advanceDialog() }
            }
            keyboard.start()
        }
        .onDisappear { keyboard.stop() }
        #endif
    }

    @ViewBuilder
    private var overlay: some View {
        switch session.overlay {
        case .none:
            EmptyView()
        case .dialog:
            if let dialog = session.dialog {
                DialogBox(dialog: dialog) { session.advanceDialog() }
            }
        case .paused:
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                if showingInventory {
                    VStack(spacing: 8) {
                        HStack {
                            Button("◀ VOLVER") { showingInventory = false }
                                .buttonStyle(.pixel(Theme.panelLight, size: 12))
                            Text("INVENTARIO").font(Theme.font(20, weight: .black)).foregroundStyle(Theme.gold)
                            Spacer()
                            GoldLabel(amount: store.profile.gold)
                        }
                        InventoryView()
                    }
                    .padding(16)
                    .background(Theme.background.opacity(0.96).ignoresSafeArea())
                } else {
                    VStack(spacing: 12) {
                        Text("PAUSA").font(Theme.font(28, weight: .black)).foregroundStyle(Theme.gold)
                        Text(session.objective).font(Theme.font(11, weight: .bold)).foregroundStyle(Theme.text)
                        Button("▶ CONTINUAR") { session.resume() }
                            .buttonStyle(.pixel(Theme.green, text: .black, size: 16))
                        Button("▤ INVENTARIO") { showingInventory = true }
                            .buttonStyle(.pixel(Theme.blue, text: .black, size: 14))
                        Button("Menú principal") { store.go(to: .menu) }
                            .buttonStyle(.pixel(Theme.panelLight, size: 12))
                        Text("La forja y el ritual están en la casa del enano (barrio este).")
                            .font(Theme.font(9, weight: .bold))
                            .foregroundStyle(Theme.textDim)
                    }
                    .padding(24)
                    .pixelPanel()
                }
            }
        case .smithy:
            SmithyView(session: session)
        case .dead:
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 12) {
                    PixelImage(image: Art.skull, scale: 5)
                    Text("HAS CAÍDO").font(Theme.font(28, weight: .black)).foregroundStyle(Theme.red)
                    Text("Conservas todo lo conseguido. Los aldeanos te llevan a la puerta sur.")
                        .font(Theme.font(11, weight: .bold))
                        .foregroundStyle(Theme.textDim)
                    Button("LEVANTARSE") { session.respawn() }
                        .buttonStyle(.pixel(Theme.green, text: .black, size: 16))
                }
                .padding(24)
                .pixelPanel()
            }
        case .victory:
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("¡VALDEHIERRO ES LIBRE!").font(Theme.font(26, weight: .black)).foregroundStyle(Theme.gold)
                    if let part = PartCatalog.part("legend.dawn") {
                        HStack(spacing: 10) {
                            PixelImage(image: Art.partImage(part), scale: 3)
                                .shadow(color: Theme.gold, radius: 10)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PIEZA LEGENDARIA").font(Theme.font(10)).foregroundStyle(Theme.orange)
                                Text(part.name).font(Theme.font(16, weight: .black)).foregroundStyle(Theme.gold)
                                Text("Llévala al ritual de la forja para despertar su poder.")
                                    .font(Theme.font(10, weight: .bold))
                                    .foregroundStyle(Theme.text)
                            }
                        }
                    }
                    Button("SEGUIR EXPLORANDO") { session.closeVictory() }
                        .buttonStyle(.pixel(Theme.green, text: .black, size: 15))
                }
                .padding(24)
                .pixelPanel()
            }
        }
    }
}

private struct ExploreHUD: View {
    @Environment(GameStore.self) private var store
    let session: ExploreSession

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HPBar(hp: session.hp, maxHP: session.maxHP, width: 170)
                Text(session.placeName.uppercased())
                    .font(Theme.font(13, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            Spacer()
            Text(session.objective)
                .font(Theme.font(11, weight: .bold))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
            Spacer()
            HStack(alignment: .top, spacing: 12) {
                GoldLabel(amount: store.profile.gold)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                if session.overlay == .none {
                    Button("II") { session.pause() }
                        .buttonStyle(.pixel(Theme.panelLight, size: 14))
                }
            }
        }
    }
}

/// Cuadro de diálogo con retrato.
private struct DialogBox: View {
    let dialog: Dialog
    let onNext: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .top, spacing: 12) {
                if let look = dialog.look {
                    PixelImage(image: Art.npcImage(look), scale: 3.4)
                        .frame(width: 80, height: 90)
                        .background(Color.black.opacity(0.35))
                        .overlay(Rectangle().strokeBorder(Theme.border, lineWidth: 2))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(dialog.speaker.uppercased())
                        .font(Theme.font(13, weight: .black))
                        .foregroundStyle(Theme.gold)
                    Text(dialog.line)
                        .font(Theme.font(14, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        Text(dialog.isLast ? "▶ Cerrar" : "▶ Siguiente")
                            .font(Theme.font(10, weight: .black))
                            .foregroundStyle(Theme.textDim)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: 720, minHeight: 110, alignment: .topLeading)
            .pixelPanel()
            .padding(.horizontal, 30)
            .padding(.bottom, 14)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onNext)
        .background(Color.black.opacity(0.25).ignoresSafeArea().onTapGesture(perform: onNext))
    }
}

/// Dentro de la forja del enano: tienda, ritual e inventario.
private struct SmithyView: View {
    enum Tab: String, CaseIterable {
        case shop = "HERRERO"
        case ritual = "RITUAL"
        case inventory = "INVENTARIO"
    }

    @Environment(GameStore.self) private var store
    let session: ExploreSession
    @State private var tab: Tab = .shop

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FORJA DEL ENANO")
                    .font(Theme.font(15, weight: .black))
                    .foregroundStyle(Theme.orange)
                HPBar(hp: session.hp, maxHP: session.maxHP, width: 130)
                Text("Nivel de la forja: \(session.progress.shopLevel)")
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                ForEach(Tab.allCases, id: \.self) { item in
                    Button(item.rawValue) { tab = item }
                        .buttonStyle(.pixel(tab == item ? Theme.gold : Theme.panelLight,
                                            text: tab == item ? .black : Theme.text, size: 13))
                }
                Spacer(minLength: 0)
                Button("◀ SALIR") { session.closeSmithy() }
                    .buttonStyle(.pixel(Theme.green, text: .black, size: 15))
            }
            .frame(width: 160, alignment: .leading)

            Group {
                switch tab {
                case .shop: if let shop = session.shop { DwarfShopView(shop: shop) }
                case .ritual: RitualForgeView(showsBackButton: false)
                case .inventory: InventoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.background.opacity(0.96).ignoresSafeArea())
    }
}
