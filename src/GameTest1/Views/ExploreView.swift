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
                    PauseMenu(session: session, showingInventory: $showingInventory)
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HPBar(hp: session.hp, maxHP: session.maxHP, width: 170)
                LevelBadge(level: session.level, progress: session.xpProgress)
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

// MARK: - Pausa: diario de misiones y mapa del continente

private struct PauseMenu: View {
    @Environment(GameStore.self) private var store
    let session: ExploreSession
    @Binding var showingInventory: Bool
    @State private var tab = Tab.journal

    enum Tab { case journal, map }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 10) {
                Text("PAUSA").font(Theme.font(26, weight: .black)).foregroundStyle(Theme.gold)
                Button("▶ CONTINUAR") { session.resume() }
                    .buttonStyle(.pixel(Theme.green, text: .black, size: 16, minHeight: 46))
                Button("▤ INVENTARIO") { showingInventory = true }
                    .buttonStyle(.pixel(Theme.blue, text: .black, size: 14, minHeight: 42))
                Button(tab == .journal ? "✦ MAPA" : "✎ DIARIO") { tab = tab == .journal ? .map : .journal }
                    .buttonStyle(.pixel(Theme.panelLight, size: 13, minHeight: 40))
                Button("◀ Salir a personajes") { store.go(to: .characterSelect) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 11, minHeight: 36))
                Text("La forja y el ritual están en la casa del enano (barrio este).")
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: 190)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 200)
            Group {
                switch tab {
                case .journal: QuestJournalView(session: session)
                case .map: ContinentMapView(profile: store.profile, currentAreaID: session.areaID)
                }
            }
            .frame(width: 400, height: 300)
        }
        .padding(18)
        .pixelPanel()
        #if DEBUG
        .onAppear { if DebugLaunch.pauseTab == "mapa" { tab = .map } }
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

/// Mapa del continente (M10): esquema de `zonas.md` §1 con las áreas visitadas, los caminos y dónde está el héroe.
struct ContinentMapView: View {
    let profile: PlayerProfile
    let currentAreaID: String

    var body: some View {
        let continent = World.continent(profile.continentID) ?? World.continents[0]
        let layout = continent.mapLayout
        let visited = profile.visitedAreaIDs ?? []
        // Un interior se marca en su exterior (la casa del alcalde en el pueblo).
        let here = layout[currentAreaID] != nil ? currentAreaID : (World.outside(of: currentAreaID)?.areaID ?? currentAreaID)
        GeometryReader { geo in
            let cols = (layout.values.map(\.x).max() ?? 0) + 1, rows = (layout.values.map(\.y).max() ?? 0) + 1
            let cellW = geo.size.width / CGFloat(cols), cellH = (geo.size.height - 24) / CGFloat(rows)
            let center = { (p: TilePoint) in CGPoint(x: (CGFloat(p.x) + 0.5) * cellW, y: 24 + (CGFloat(p.y) + 0.5) * cellH) }
            ZStack {
                Text(continent.name.uppercased())
                    .font(Theme.font(14, weight: .black)).foregroundStyle(Theme.gold)
                    .position(x: geo.size.width / 2, y: 10)
                // Caminos entre áreas (salidas que llevan a otra área del esquema).
                Path { path in
                    for (id, from) in layout {
                        for exit in World.area(id)?.exits ?? [] {
                            guard let to = layout[exit.toArea] else { continue }
                            path.move(to: center(from))
                            path.addLine(to: center(to))
                        }
                    }
                }
                .stroke(Theme.textDim, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                ForEach(Array(layout.keys.sorted()), id: \.self) { id in
                    let area = World.area(id)
                    let seen = visited.contains(id) || id == here
                    VStack(spacing: 2) {
                        Text(seen ? (area?.name ?? id) : "???")
                            .font(Theme.font(10, weight: .black))
                            .foregroundStyle(id == here ? Color.black : Theme.text)
                            .multilineTextAlignment(.center)
                        if seen, let area {
                            let range = area.levelRange
                            Text(range.lowerBound == range.upperBound ? "Nv \(range.lowerBound)" : "Nv \(range.lowerBound)-\(range.upperBound)")
                                .font(Theme.font(9, weight: .bold))
                                .foregroundStyle(id == here ? Color.black : Theme.textDim)
                        }
                    }
                    .padding(6)
                    .frame(width: cellW - 16, height: min(54, cellH - 14))
                    .background(id == here ? Theme.gold : (seen ? Theme.panelLight : Color.black.opacity(0.6)))
                    .overlay(Rectangle().strokeBorder(Theme.border, lineWidth: 2))
                    .position(center(layout[id]!))
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
    }
}
