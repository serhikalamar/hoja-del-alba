import GameCore
import SwiftUI

/// Elección de raza (al empezar partida o desde el menú).
struct RaceSelectView: View {
    @Environment(GameStore.self) private var store
    @State private var selected: Race = .human

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if store.profile.hasChosenRace {
                    Button("◀ MENÚ") { store.go(to: .menu) }
                        .buttonStyle(.pixel(Theme.panelLight, size: 12))
                }
                Text("ELIGE TU RAZA")
                    .font(Theme.font(24, weight: .black))
                    .foregroundStyle(Theme.gold)
                Spacer()
            }
            HStack(spacing: 12) {
                ForEach(Race.allCases) { race in
                    raceCard(race)
                }
            }
            Button("¡EMPEZAR COMO \(selected.name.uppercased())!") { store.chooseRace(selected) }
                .buttonStyle(.pixel(Theme.green, text: .black, size: 16))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onAppear { selected = store.profile.race }
    }

    /// Estadísticas especiales que destacan de cada raza.
    private static func extraStats(_ stats: Stats) -> [StatKind] {
        var kinds: [StatKind] = [.lifesteal, .goldBonus, .regen].filter { stats[$0] > 0 }
        if stats.critChance > 0.05 { kinds.insert(.critChance, at: 0) }
        return kinds
    }

    private func raceCard(_ race: Race) -> some View {
        let stats = race.baseStats
        let isSelected = race == selected
        return Button {
            selected = race
        } label: {
            VStack(spacing: 6) {
                PixelImage(image: Art.heroImage(armorIcon: store.profile.equippedArmor?.icon ?? "armor_tunic", race: race), scale: 3.4)
                Text(race.name.uppercased())
                    .font(Theme.font(14, weight: .black))
                    .foregroundStyle(isSelected ? Theme.gold : Theme.text)
                Text(race.summary)
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 34)
                VStack(alignment: .leading, spacing: 1) {
                    ForEach([StatKind.maxHP, .attack, .defense, .attackSpeed, .range, .moveSpeed], id: \.self) { kind in
                        HStack {
                            Text(kind.shortName).foregroundStyle(Theme.textDim)
                            Spacer()
                            Text(kind.formatValue(stats[kind])).foregroundStyle(Theme.text)
                        }
                        .font(Theme.font(9, weight: .bold))
                    }
                    let extras = Self.extraStats(stats)
                    ForEach(extras, id: \.self) { kind in
                        HStack {
                            Text(kind.shortName)
                            Spacer()
                            Text(kind.formatValue(stats[kind]))
                        }
                        .font(Theme.font(9, weight: .bold))
                        .foregroundStyle(Theme.green)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .pixelPanel(fill: isSelected ? Theme.panelLight : Theme.panel, border: isSelected ? Theme.gold : Theme.border)
        }
        .buttonStyle(.plain)
    }
}
