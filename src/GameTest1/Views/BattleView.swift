import GameCore
import SpriteKit
import SwiftUI

struct BattleView: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession
    /// Ficha del personaje abierta desde el retrato del HUD (con la arena en pausa).
    @State private var showingProfile = false
    #if os(macOS)
    @State private var keyboard = KeyboardMovement()
    #endif

    var body: some View {
        ZStack {
            SpriteView(scene: session.scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            #if os(iOS)
            if session.phase == .fighting {
                JoystickArea { session.joystick = $0 }
                    .ignoresSafeArea()
            }
            #endif

            VStack(spacing: 10) {
                BattleHUD(session: session) {
                    session.pause()
                    showingProfile = session.phase == .paused
                }
                if let banner = session.banner {
                    Text(banner)
                        .font(Theme.font(20, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(duration: 0.3), value: session.banner)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            overlay
        }
        .onChange(of: session.phase) { _, phase in
            if phase != .paused { showingProfile = false }
        }
        #if DEBUG
        .onAppear {
            if DebugLaunch.openProfile {
                DebugLaunch.openProfile = false
                session.pause()
                showingProfile = true
            }
        }
        #endif
        #if os(macOS)
        .onAppear {
            let session = self.session
            keyboard.onChange = { [weak session] in session?.joystick = $0 }
            keyboard.onEscape = { [weak session] in
                guard let session else { return }
                if session.phase == .fighting { session.pause() } else if session.phase == .paused { session.resume() }
            }
            keyboard.onAction = { [weak session] in
                if session?.phase == .storyDialog { session?.advanceStoryDialog() }
            }
            keyboard.start()
        }
        .onDisappear { keyboard.stop() }
        #endif
    }

    @ViewBuilder
    private var overlay: some View {
        switch session.phase {
        case .fighting:
            EmptyView()
        case .intro:
            Dimmed { LevelIntroPanel(session: session) }
        case .paused:
            if showingProfile {
                CharacterSheetView { session.resume() }
            } else {
                Dimmed { PausePanel(session: session) }
            }
        case .intermission:
            IntermissionView(session: session)
        case .waveBreak:
            VStack {
                Spacer()
                Text(session.isStory ? "¡OLEADA \(session.wave) SUPERADA!" : "¡OLEADA \(session.wave) SUPERADA!  +\(session.lastWaveReward) oro")
                    .font(Theme.font(16, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .padding(10)
                    .background(Color.black.opacity(0.65))
                Text(session.nextWaveHasBoss ? "Prepárate: ¡la siguiente oleada trae un jefe!" : "La siguiente oleada empieza enseguida…")
                    .font(Theme.font(11, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                Spacer()
            }
        case .defeat:
            if session.isStory {
                Dimmed { StoryEndPanel(session: session) }
            } else {
                Dimmed { DefeatPanel(session: session) }
            }
        case .storyVictory:
            Dimmed { StoryEndPanel(session: session) }
        case .storyDialog:
            if let dialog = session.storyDialog {
                StoryDialogBox(speaker: dialog.speaker, line: dialog.lines[dialog.index],
                               isLast: dialog.index >= dialog.lines.count - 1) { session.advanceStoryDialog() }
            }
        }
    }
}

private struct Dimmed<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            content
        }
    }
}

// MARK: - HUD

private struct BattleHUD: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession
    /// Al tocar el retrato: ficha del personaje.
    let onPortrait: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HeroPortraitButton(look: HeroLook(profile: store.profile), action: onPortrait)
                .disabled(session.phase != .fighting)
            VStack(alignment: .leading, spacing: 4) {
                HPBar(hp: session.hp, maxHP: session.maxHP, width: 170)
                LevelBadge(level: session.level, progress: session.xpProgress)
                Text(session.totalWaves.map { "OLEADA \(max(1, session.wave))/\($0)" } ?? "OLEADA \(max(1, session.wave))")
                    .font(Theme.font(15, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(session.story.map { $0.name.uppercased() } ?? "PISO \(session.depth) · \(session.floor.name.uppercased())")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.textDim)
                Text("ENEMIGOS: \(session.enemiesLeft)")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.text)
                if !session.isStory {
                    Text("Récord: \(session.bestWave)")
                        .font(Theme.font(10, weight: .bold))
                        .foregroundStyle(Theme.textDim)
                }
            }
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            Spacer()
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    GoldLabel(amount: store.profile.gold)
                    HStack(spacing: 4) {
                        PixelImage(image: Art.mineralImage(.emerald), scale: 2)
                        Text("+\(session.totalMineralsEarned)")
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.text)
                    }
                }
                .shadow(color: .black, radius: 0, x: 2, y: 2)
                if session.phase == .fighting {
                    Button("II") { session.pause() }
                        .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 44))
                        .frame(minWidth: 44)
                }
            }
        }
    }
}

// MARK: - Joystick

/// Joystick flotante: aparece donde el jugador toca y arrastra.
struct JoystickArea: View {
    var onChange: (CGVector) -> Void
    /// ¿Este punto cae sobre algo que se toca (un NPC)? Entonces no aparece el joystick: es un toque.
    var isTappable: (CGPoint) -> Bool = { _ in false }
    /// Toque sobre algo `isTappable` (sin arrastrar).
    var onTap: (CGPoint) -> Void = { _ in }
    @State private var origin: CGPoint?
    /// Toque que empezó sobre un NPC (si se arrastra lejos, pasa a ser el joystick desde ahí).
    @State private var tapStart: CGPoint?
    @State private var knob: CGSize = .zero
    private let radius: CGFloat = 55

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear.contentShape(Rectangle())
                if let origin {
                    stick(at: origin, knob: knob).opacity(0.9)
                } else {
                    stick(at: CGPoint(x: 120, y: geo.size.height - 95), knob: .zero).opacity(0.3)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if origin == nil, tapStart == nil, isTappable(value.startLocation) {
                            tapStart = value.startLocation
                        }
                        if let start = tapStart {
                            guard hypot(value.location.x - start.x, value.location.y - start.y) > 24 else { return }
                            tapStart = nil
                            origin = start
                        }
                        if origin == nil { origin = value.startLocation }
                        let start = origin ?? value.startLocation
                        var dx = value.location.x - start.x
                        var dy = value.location.y - start.y
                        let length = hypot(dx, dy)
                        if length > radius {
                            dx = dx / length * radius
                            dy = dy / length * radius
                        }
                        knob = CGSize(width: dx, height: dy)
                        // SwiftUI tiene la Y hacia abajo; SpriteKit hacia arriba.
                        onChange(length < 6 ? .zero : CGVector(dx: dx / radius, dy: -dy / radius))
                    }
                    .onEnded { _ in
                        if let start = tapStart {
                            tapStart = nil
                            onTap(start)
                            return
                        }
                        origin = nil
                        knob = .zero
                        onChange(.zero)
                    }
            )
        }
    }

    private func stick(at point: CGPoint, knob: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.25))
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 3))
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .fill(Color.white.opacity(0.8))
                .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 3))
                .frame(width: 46, height: 46)
                .offset(knob)
        }
        .position(point)
        .allowsHitTesting(false)
    }
}

// MARK: - Paneles

private struct LevelIntroPanel: View {
    let session: BattleSession

    #if os(macOS)
    static let controlsHint = "Muévete con WASD o flechas (Esc: pausa)."
    #else
    static let controlsHint = "Arrastra para moverte."
    #endif

    var body: some View {
        VStack(spacing: 10) {
            Text("ARENA")
                .font(Theme.font(30, weight: .black))
                .foregroundStyle(Theme.gold)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(["rat", "goblin", "goblinSlinger", "mangyDog", "ratKing"], id: \.self) { id in
                    PixelImage(image: Art.enemyImage(id), scale: id == "ratKing" ? 3.2 : 2.6)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("• Oleadas infinitas, cada vez más difíciles.")
                Text("• Cada 2 oleadas: forja del enano y ritual.")
                Text("• Cada 5 oleadas: un jefe y bajas un piso de la mazmorra.")
                Text("• \(Self.controlsHint) Tu héroe ataca solo.")
            }
            .font(Theme.font(12, weight: .bold))
            .foregroundStyle(Theme.text)
            if session.bestWave > 0 {
                Text("Tu récord: oleada \(session.bestWave)")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.orange)
            }
            Button("¡A LUCHAR!") { session.startNextWave() }
                .buttonStyle(.pixel(Theme.red, size: 20, minHeight: 52))
                .padding(.top, 4)
        }
        .padding(20)
        .pixelPanel()
    }
}

private struct PausePanel: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession
    @State private var showingInventory = false

    var body: some View {
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
            VStack(spacing: 12) {
                Text("PAUSA").font(Theme.font(28, weight: .black)).foregroundStyle(Theme.gold)
                Button("▶ CONTINUAR") { session.resume() }
                    .buttonStyle(.pixel(Theme.green, text: .black, size: 18, minHeight: 50))
                Button("▤ INVENTARIO") { showingInventory = true }
                    .buttonStyle(.pixel(Theme.blue, text: .black, size: 16, minHeight: 46))
                if session.isStory {
                    Button("◀ Salir de la mazmorra") { session.leaveStory() }
                        .buttonStyle(.pixel(Theme.panelLight, size: 12, minHeight: 40))
                } else {
                    Button("◀ Abandonar la arena") { store.go(to: .characterSelect) }
                        .buttonStyle(.pixel(Theme.panelLight, size: 12, minHeight: 40))
                }
                Text(session.isStory ? "Los minerales y el oro conseguidos se conservan."
                                     : "Si abandonas, la partida termina: solo se guarda tu récord.")
                    .font(Theme.font(10, weight: .bold))
                    .foregroundStyle(Theme.textDim)
            }
            .padding(24)
            .pixelPanel()
        }
    }
}

private struct LootSummary: View {
    let session: BattleSession

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                GoldLabel(amount: session.goldEarned, prefix: "+", size: 18)
                Text("☠ \(session.kills)")
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.text)
            }
            ForEach(Array(session.partsEarned.enumerated()), id: \.offset) { _, part in
                HStack(spacing: 8) {
                    PixelImage(image: Art.partImage(part), scale: 2.4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("¡PIEZA ESPECIAL!").font(Theme.font(10)).foregroundStyle(Theme.orange)
                        Text(part.name).font(Theme.font(13, weight: .black)).foregroundStyle(Theme.gold)
                    }
                }
            }
            let minerals = Mineral.allCases.filter { session.mineralsEarned[$0, default: 0] > 0 }
            if minerals.isEmpty {
                Text("Sin minerales").font(Theme.font(11)).foregroundStyle(Theme.textDim)
            } else {
                HStack(spacing: 10) {
                    ForEach(minerals) { mineral in
                        MineralChip(mineral: mineral, count: session.mineralsEarned[mineral, default: 0], scale: 3)
                    }
                }
            }
        }
    }
}

private struct DefeatPanel: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession

    var body: some View {
        VStack(spacing: 10) {
            PixelImage(image: Art.skull, scale: 5)
            Text("HAS CAÍDO EN LA OLEADA \(session.wave)")
                .font(Theme.font(24, weight: .black))
                .foregroundStyle(Theme.red)
            Text(session.isNewRecord ? "¡NUEVO RÉCORD!" : "Récord: oleada \(session.bestWave)")
                .font(Theme.font(14, weight: .black))
                .foregroundStyle(session.isNewRecord ? Theme.gold : Theme.textDim)
            Text("Conservas todo el botín conseguido.")
                .font(Theme.font(11, weight: .bold))
                .foregroundStyle(Theme.textDim)
            LootSummary(session: session)
            HStack(spacing: 12) {
                Button("◀ PERSONAJES") { store.go(to: .characterSelect) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 46))
                Button("▶ HISTORIA") { store.startTown() }
                    .buttonStyle(.pixel(Theme.blue, text: .black, size: 14, minHeight: 46))
                Button("⚔ OTRA VEZ") { store.startArena() }
                    .buttonStyle(.pixel(Theme.green, text: .black, size: 14, minHeight: 46))
            }
        }
        .padding(22)
        .pixelPanel()
    }
}

// MARK: - Mazmorra de historia

/// Final de una mazmorra de historia: ganada (vuelve a la bajada) o perdida (al punto seguro del área).
private struct StoryEndPanel: View {
    let session: BattleSession

    var body: some View {
        let won = session.phase == .storyVictory
        VStack(spacing: 10) {
            if !won { PixelImage(image: Art.skull, scale: 5) }
            Text(won ? "¡VICTORIA!" : "HAS CAÍDO")
                .font(Theme.font(26, weight: .black))
                .foregroundStyle(won ? Theme.gold : Theme.red)
            Text(won ? session.storyMessage : (session.story.flatMap { ValdemarDialogue.dungeonTexts[$0.id]?.lose }
                                                ?? "Despiertas en el punto seguro. Conservas todo el botín."))
                .font(Theme.font(12, weight: .bold))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
            LootSummary(session: session)
            Button(won ? "▶ VOLVER" : "LEVANTARSE") { session.leaveStory() }
                .buttonStyle(.pixel(Theme.green, text: .black, size: 16, minHeight: 46))
        }
        .padding(22)
        .pixelPanel()
    }
}

/// Diálogo dentro de la mazmorra (la confesión del jefe). Se avanza tocando.
private struct StoryDialogBox: View {
    let speaker: String
    let line: String
    let isLast: Bool
    let onNext: () -> Void

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 4) {
                Text(speaker.uppercased())
                    .font(Theme.font(12, weight: .black))
                    .foregroundStyle(Theme.red)
                Text(line)
                    .font(Theme.font(14, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(isLast ? "▶ ¡A luchar!" : "▶ Siguiente")
                    .font(Theme.font(10, weight: .black))
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: 480, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .pixelPanel(fill: Theme.panel.opacity(0.95))
            .padding(.horizontal, 30)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onNext)
    }
}
