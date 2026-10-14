import GameCore
import SpriteKit
import SwiftUI

/// Pantalla de exploración del pueblo.
struct ExploreView: View {
    @Environment(GameStore.self) private var store
    let session: ExploreSession
    #if os(macOS)
    @State private var keyboard = KeyboardMovement()
    #endif

    var body: some View {
        ZStack {
            SpriteView(scene: session.scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            #if os(iOS)
            // Tocar a un NPC habla con él (o camina hasta él); en el resto de la pantalla, el joystick de siempre.
            if session.overlay == .none {
                JoystickArea(onChange: { session.joystick = $0 },
                             isTappable: { session.isNPC(atScreen: $0) },
                             onTap: { session.tap(atScreen: $0) })
                    .ignoresSafeArea()
            }
            #else
            // Mac: clic sobre un NPC para hablar con él.
            if session.overlay == .none {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { session.tap(atScreen: $0) }
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
            .animation(.easeOut(duration: 0.3), value: session.areaBanner)

            // Cartel del área al entrar ("Bosque de Robleda · 6-7").
            if let banner = session.areaBanner, session.overlay == .none {
                Text(banner.uppercased())
                    .font(Theme.font(22, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.45))
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .offset(y: -50)
            }

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
                case .paused: session.resume()   // también cierra el mapa o el inventario
                case .smithy: session.closeSmithy()
                case .profile, .quests: session.closePanel()
                default: break
                }
            }
            // Espacio, Intro o E: pasa el diálogo o habla con el NPC más cercano al alcance.
            keyboard.onAction = { [weak session] in
                switch session?.overlay {
                case .dialog?: session?.advanceDialog()
                case .none?: session?.talkToNearest()
                default: break
                }
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
                if session.showingMap {
                    // Mapa del continente a pantalla completa (`ContinentMapView.swift`); al cerrar se sigue jugando.
                    ContinentMapView(profile: store.profile, currentAreaID: session.areaID, heroTile: session.heroTile) {
                        session.resume()
                    }
                } else if session.showingInventory {
                    VStack(spacing: 8) {
                        HStack {
                            Button("◀ VOLVER") { session.resume() }
                                .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 44))
                            Text("INVENTARIO").font(Theme.font(20, weight: .black)).foregroundStyle(Theme.gold)
                            Spacer()
                            GoldLabel(amount: store.profile.gold)
                        }
                        InventoryView(allowsTrading: false)
                    }
                    .padding(16)
                    .background(Theme.background.opacity(0.96).ignoresSafeArea())
                } else {
                    PauseMenu(session: session)
                }
            }
        case .smithy:
            SmithyView(session: session)
        case .profile:
            CharacterSheetView { session.closePanel() }
        case .quests:
            QuestPanelView(session: session)
        case .dead:
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 12) {
                    PixelImage(image: Art.skull, scale: 5)
                    Text("HAS CAÍDO").font(Theme.font(28, weight: .black)).foregroundStyle(Theme.red)
                    Text(session.deathMessage)
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
        let playing = session.overlay == .none
        HStack(alignment: .top, spacing: 8) {
            // Retrato del héroe: abre su ficha.
            HeroPortraitButton(look: HeroLook(profile: store.profile)) { session.openProfile() }
                .disabled(!playing)
            VStack(alignment: .leading, spacing: 4) {
                HPBar(hp: session.hp, maxHP: session.maxHP, width: 170)
                LevelBadge(level: session.level, progress: session.xpProgress)
                Text(session.placeName.uppercased())
                    .font(Theme.font(13, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            Spacer()
            // Arriba a la derecha (no en el centro, donde tapaba el "!" del Capitán): oro, "!" de la misión y pausa;
            // debajo, el objetivo en corto (al tocarlo también se abre el panel de la misión).
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .center, spacing: 10) {
                    GoldLabel(amount: store.profile.gold)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    // Mapa e inventario, junto al "!" de la misión (pausan el juego mientras están abiertos).
                    HUDIconButton(key: "hud.mapa", icon: Sprites.mapIcon, label: "Mapa") { session.openMap() }
                        .disabled(!playing)
                    HUDIconButton(key: "hud.inventario", icon: Sprites.bagIcon, label: "Inventario") { session.openInventory() }
                        .disabled(!playing)
                    QuestButton(alerts: session.questAlerts.count, isNew: session.hasNewAlert) { session.openQuests() }
                        .disabled(!playing)
                    if playing {
                        Button("II") { session.pause() }
                            .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 44))
                            .frame(minWidth: 44)
                    }
                }
                Text(session.objective)
                    .font(Theme.font(10, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 230, alignment: .trailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.45))
                    .onTapGesture { if playing { session.openQuests() } }
            }
        }
    }
}

/// Cuadro de diálogo con retrato: abajo, del tamaño justo del texto (no tapa la pantalla).
/// Se avanza tocando en cualquier sitio.
private struct DialogBox: View {
    let dialog: Dialog
    let onNext: () -> Void

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            HStack(alignment: .center, spacing: 10) {
                if let look = dialog.look {
                    portrait(look)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(dialog.currentSpeaker.uppercased())
                        .font(Theme.font(12, weight: .black))
                        .foregroundStyle(Theme.gold)
                    Text(dialog.line)
                        .font(Theme.font(14, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(dialog.isLast ? "▶ Cerrar" : "▶ Siguiente")
                        .font(Theme.font(10, weight: .black))
                        .foregroundStyle(Theme.textDim)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: 480, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .pixelPanel(fill: Theme.panel.opacity(0.95))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 30)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onNext)
    }

    @ViewBuilder
    private func portrait(_ look: String) -> some View {
        Group {
            if let chibi = NPCLooks.look(look) {
                PixelImage(image: Art.heroImage(chibi), scale: 1.25)
            } else {
                PixelImage(image: Art.npcImage(look), scale: 2.4)
            }
        }
        .frame(width: 62, height: 68)
        .background(Color.black.opacity(0.35))
        .overlay(Rectangle().strokeBorder(Theme.border, lineWidth: 2))
    }
}

/// Dentro de la forja del enano: tienda, ritual, armería y venta.
private struct SmithyView: View {
    @Environment(GameStore.self) private var store
    let session: ExploreSession

    var body: some View {
        ForgeShopView(shop: session.shop, hp: session.hp, maxHP: session.maxHP,
                      primaryTitle: "◀ SALIR", primaryAction: { session.closeSmithy() },
                      bubbles: ValdemarDialogue.smithBubbles(for: store.profile)) {
            Text("FORJA DEL ENANO")
                .font(Theme.font(16, weight: .black))
                .foregroundStyle(Theme.orange)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
    }
}

// MARK: - Pausa: continuar o cambiar de personaje

private struct PauseMenu: View {
    @Environment(GameStore.self) private var store
    let session: ExploreSession

    var body: some View {
        VStack(spacing: 12) {
            Text("PAUSA").font(Theme.font(28, weight: .black)).foregroundStyle(Theme.gold)
            Button("▶ CONTINUAR") { session.resume() }
                .buttonStyle(.pixel(Theme.green, text: .black, size: 18, minHeight: 50))
            Button("◀ CAMBIAR DE PERSONAJE") { store.go(to: .characterSelect) }
                .buttonStyle(.pixel(Theme.panelLight, size: 13, minHeight: 44))
        }
        .frame(width: 260)
        .padding(24)
        .pixelPanel()
        #if DEBUG
        .onAppear {
            if DebugLaunch.pauseTab == "mapa" { session.openMap() }
            if DebugLaunch.pauseTab == "inventario" { session.openInventory() }
        }
        #endif
    }
}

/// Diario: misiones en curso con su progreso y misiones cumplidas.
struct QuestJournalView: View {
    let session: ExploreSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("DIARIO").font(Theme.font(16, weight: .black)).foregroundStyle(Theme.gold)
                Text("EN CURSO").font(Theme.font(10, weight: .black)).foregroundStyle(Theme.orange)
                if session.activeQuests.isEmpty {
                    Text(session.objective).font(Theme.font(11, weight: .bold)).foregroundStyle(Theme.text)
                }
                ForEach(session.activeQuests, id: \.id) { quest in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(quest.title).font(Theme.font(12, weight: .black)).foregroundStyle(Theme.text)
                        Text(quest.summary).font(Theme.font(9, weight: .bold)).foregroundStyle(Theme.textDim)
                        ForEach(Array(session.journal(quest).enumerated()), id: \.offset) { _, line in
                            Text((line.isDone ? "✔ " : "· ") + line.text + (line.counter.isEmpty ? "" : " \(line.counter)"))
                                .font(Theme.font(10, weight: .bold))
                                .foregroundStyle(line.isDone ? Theme.green : Theme.text)
                        }
                    }
                }
                if !session.finishedQuests.isEmpty {
                    Text("CUMPLIDAS").font(Theme.font(10, weight: .black)).foregroundStyle(Theme.orange).padding(.top, 4)
                    ForEach(session.finishedQuests, id: \.id) { quest in
                        Text("✔ " + quest.title).font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.textDim)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
    }
}
