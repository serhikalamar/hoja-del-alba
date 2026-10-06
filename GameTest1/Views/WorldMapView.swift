import GameCore
import SwiftUI

struct WorldMapView: View {
    @Environment(GameStore.self) private var store
    /// Vista del pueblo detrás del camino de niveles.
    private static let backdrop = VillageArt.background(width: 340, height: 120, level: Worlds.village.levels[0])

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button("◀ MENÚ") { store.go(to: .menu) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 12))
                Text("MUNDO 1 · \(store.world.name.uppercased())")
                    .font(Theme.font(20, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .padding(.leading, 8)
                Spacer()
                GoldLabel(amount: store.profile.gold)
            }

            GeometryReader { geo in
                let points = nodePositions(in: geo.size)
                ZStack {
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        points.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(Color(hex: 0x8F563B), style: StrokeStyle(lineWidth: 6, dash: [8, 6]))

                    ForEach(store.world.levels) { level in
                        LevelNode(
                            number: level.id,
                            unlocked: store.profile.isUnlocked(level: level.id),
                            completed: store.profile.completedLevels.contains(level.id),
                            selected: store.selectedLevel == level.id,
                            isBoss: level.id == store.world.levels.count
                        ) {
                            store.selectedLevel = level.id
                        }
                        .position(points[level.id - 1])
                    }
                }
            }
            .background(
                Image(decorative: Self.backdrop, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .opacity(0.55)
            )
            .clipped()
            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))

            if let level = store.world.level(store.selectedLevel) {
                LevelDetail(level: level)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    /// Camino en zig-zag de izquierda a derecha.
    private func nodePositions(in size: CGSize) -> [CGPoint] {
        let count = store.world.levels.count
        let marginX: CGFloat = 36
        let step = (size.width - marginX * 2) / CGFloat(max(1, count - 1))
        return (0..<count).map { i in
            let y = size.height * (i.isMultiple(of: 2) ? 0.65 : 0.35)
            return CGPoint(x: marginX + step * CGFloat(i), y: y)
        }
    }
}

private struct LevelNode: View {
    let number: Int
    let unlocked: Bool
    let completed: Bool
    let selected: Bool
    let isBoss: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(unlocked ? (completed ? Theme.green : Theme.gold) : Theme.panelLight)
                    .frame(width: 42, height: 42)
                    .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
                    .overlay(Rectangle().strokeBorder(selected ? Color.white : .clear, lineWidth: 3).padding(-6))
                if unlocked {
                    Text("\(number)")
                        .font(Theme.font(18, weight: .black))
                        .foregroundStyle(.black)
                } else {
                    Text("🔒").font(.system(size: 16))
                }
                if isBoss {
                    PixelImage(image: Art.skull, scale: 2.4).offset(x: 18, y: -20)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .scaleEffect(selected ? 1.12 : 1)
        .animation(.spring(duration: 0.2), value: selected)
    }
}

private struct LevelDetail: View {
    @Environment(GameStore.self) private var store
    let level: LevelDefinition

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NIVEL \(level.id) · \(level.name.uppercased())")
                    .font(Theme.font(15, weight: .black))
                    .foregroundStyle(Theme.text)
                Text("\(level.roundCount) rondas · \(level.waves.map(\.totalMonsters).reduce(0, +)) enemigos")
                    .font(Theme.font(11, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                HStack(spacing: 4) {
                    Text("Recompensa:").font(Theme.font(11, weight: .bold)).foregroundStyle(Theme.textDim)
                    GoldLabel(amount: totalReward, prefix: "~", size: 12)
                }
                if let boss = level.boss, let part = boss.specialPartID.flatMap(PartCatalog.part) {
                    HStack(spacing: 4) {
                        Text(store.profile.defeatedBosses.contains(boss.id) ? "✓ Jefe:" : "Jefe:")
                            .foregroundStyle(store.profile.defeatedBosses.contains(boss.id) ? Theme.green : Theme.orange)
                        Text("\(boss.name) → \(part.name)").foregroundStyle(Theme.gold)
                    }
                    .font(Theme.font(9, weight: .bold))
                }
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(level.newEnemies) { enemy in
                    VStack(spacing: 2) {
                        PixelImage(image: Art.enemyImage(enemy.id), scale: enemy.isBoss ? 2.6 : 2.2)
                        Text(enemy.name)
                            .font(Theme.font(7))
                            .foregroundStyle(enemy.isBoss ? Theme.orange : Theme.textDim)
                            .frame(width: 58)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            Spacer()
            Button("¡LUCHAR!") { store.startBattle(level: level.id) }
                .buttonStyle(.pixel(Theme.red, size: 18))
                .disabled(!store.profile.isUnlocked(level: level.id))
        }
        .padding(10)
        .pixelPanel()
    }

    private var totalReward: Int {
        (1...level.roundCount).map(level.roundReward).reduce(0, +) + level.clearBonus
    }
}
