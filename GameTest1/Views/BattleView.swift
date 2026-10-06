import GameCore
import SpriteKit
import SwiftUI

struct BattleView: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession
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

            VStack {
                BattleHUD(session: session)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            overlay
        }
        #if os(macOS)
        .onAppear {
            let session = self.session
            keyboard.onChange = { [weak session] in session?.joystick = $0 }
            keyboard.onEscape = { [weak session] in
                guard let session else { return }
                if session.phase == .fighting { session.pause() } else if session.phase == .paused { session.resume() }
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
            Dimmed { PausePanel(session: session) }
        case .intermission:
            IntermissionView(session: session)
        case .victory:
            Dimmed { VictoryPanel(session: session) }
        case .defeat:
            Dimmed { DefeatPanel(session: session) }
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

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HPBar(hp: session.hp, maxHP: session.maxHP, width: 170)
                Text("RONDA \(max(1, session.round))/\(session.totalRounds)")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.text)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("NV.\(session.level.id) \(session.level.name.uppercased())")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.textDim)
                Text("GOBLINS: \(session.enemiesLeft)")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.text)
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
                        .buttonStyle(.pixel(Theme.panelLight, size: 14))
                }
            }
        }
    }
}

// MARK: - Joystick

/// Joystick flotante: aparece donde el jugador toca y arrastra.
struct JoystickArea: View {
    var onChange: (CGVector) -> Void
    @State private var origin: CGPoint?
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
            Text("NIVEL \(session.level.id)")
                .font(Theme.font(14))
                .foregroundStyle(Theme.textDim)
            Text(session.level.name.uppercased())
                .font(Theme.font(26, weight: .black))
                .foregroundStyle(Theme.gold)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(session.level.newEnemies) { enemy in
                    PixelImage(image: Art.enemyImage(enemy.id), scale: enemy.isBoss ? 3.4 : 2.8)
                }
            }
            if let boss = session.level.boss {
                Text("Jefe final: \(boss.name)")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.orange)
            }
            Text("\(session.totalRounds) rondas · \(Self.controlsHint)\nTu héroe ataca solo al acercarse un enemigo.")
                .font(Theme.font(12, weight: .bold))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            Button("¡A LUCHAR!") { session.startNextRound() }
                .buttonStyle(.pixel(Theme.red, size: 18))
                .padding(.top, 4)
        }
        .padding(20)
        .pixelPanel()
    }
}

private struct PausePanel: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession

    var body: some View {
        VStack(spacing: 12) {
            Text("PAUSA").font(Theme.font(28, weight: .black)).foregroundStyle(Theme.gold)
            Button("▶ CONTINUAR") { session.resume() }
                .buttonStyle(.pixel(Theme.green, text: .black, size: 16))
            Button("Abandonar nivel") { store.go(to: .worldMap) }
                .buttonStyle(.pixel(Theme.panelLight, size: 12))
            Text("Los minerales y el oro conseguidos se conservan.")
                .font(Theme.font(10, weight: .bold))
                .foregroundStyle(Theme.textDim)
        }
        .padding(24)
        .pixelPanel()
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

private struct VictoryPanel: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession

    var body: some View {
        VStack(spacing: 12) {
            Text("¡NIVEL COMPLETADO!")
                .font(Theme.font(26, weight: .black))
                .foregroundStyle(Theme.gold)
            Text("Bonus de nivel: +\(session.levelClearBonus) oro")
                .font(Theme.font(12, weight: .bold))
                .foregroundStyle(Theme.textDim)
            LootSummary(session: session)
            HStack(spacing: 12) {
                Button("MAPA") { store.go(to: .worldMap) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 14))
                Button("RITUAL") { store.go(to: .forge) }
                    .buttonStyle(.pixel(Theme.purple, text: .white, size: 14))
                let next = session.level.id + 1
                if store.world.level(next) != nil {
                    Button("NIVEL \(next) ▶") { store.startBattle(level: next) }
                        .buttonStyle(.pixel(Theme.green, text: .black, size: 14))
                } else {
                    Text("¡Mundo 1 completado!")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.green)
                }
            }
        }
        .padding(22)
        .pixelPanel()
    }
}

private struct DefeatPanel: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession

    var body: some View {
        VStack(spacing: 12) {
            PixelImage(image: Art.skull, scale: 5)
            Text("HAS CAÍDO")
                .font(Theme.font(28, weight: .black))
                .foregroundStyle(Theme.red)
            Text("Ronda \(session.round)/\(session.totalRounds) · Conservas el botín conseguido.")
                .font(Theme.font(11, weight: .bold))
                .foregroundStyle(Theme.textDim)
            LootSummary(session: session)
            HStack(spacing: 12) {
                Button("MAPA") { store.go(to: .worldMap) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 14))
                Button("RITUAL") { store.go(to: .forge) }
                    .buttonStyle(.pixel(Theme.purple, text: .white, size: 14))
                Button("REINTENTAR") { store.startBattle(level: session.level.id) }
                    .buttonStyle(.pixel(Theme.green, text: .black, size: 14))
            }
        }
        .padding(22)
        .pixelPanel()
    }
}
