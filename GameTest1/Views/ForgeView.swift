import GameCore
import SwiftUI

/// Forja: eliges el tipo de objeto, combinas minerales y giras la ruleta.
struct ForgeView: View {
    @Environment(GameStore.self) private var store
    @State private var blueprintID = "short_sword"
    @State private var selection: [Mineral: Int] = [:]
    @State private var pending: (result: CraftResult, luck: Double)?
    @State private var errorMessage: String?

    private var blueprint: Blueprint {
        Catalog.blueprint(id: blueprintID) ?? Catalog.blueprints[0]
    }

    private var recipe: CraftRecipe {
        CraftRecipe(blueprint: blueprint, minerals: selection)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            blueprintColumn.frame(width: 168)
            mineralColumn.frame(maxWidth: .infinity)
            resultColumn.frame(width: 178)
        }
        .overlay {
            if let pending {
                RouletteView(result: pending.result, luck: pending.luck) {
                    self.pending = nil
                }
            }
        }
    }

    // MARK: 1. Objeto

    private var blueprintColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("1. OBJETO").font(Theme.font(12)).foregroundStyle(Theme.textDim)
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(Catalog.blueprints) { bp in
                        let locked = bp.tier > store.profile.maxCraftTier
                        Button {
                            blueprintID = bp.id
                            errorMessage = nil
                        } label: {
                            HStack(spacing: 6) {
                                PixelImage(image: Art.itemImage(icon: bp.icon), scale: 2)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(bp.name)
                                        .font(Theme.font(10, weight: .black))
                                        .foregroundStyle(Theme.text)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Text(locked ? "🔒 Nivel \(unlockLevel(tier: bp.tier))" : "T\(bp.tier) · \(bp.slot.name)")
                                        .font(Theme.font(8, weight: .bold))
                                        .foregroundStyle(Theme.textDim)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(5)
                            .background(bp.id == blueprintID ? Theme.panelLight : Theme.panel)
                            .overlay(Rectangle().strokeBorder(bp.id == blueprintID ? Theme.gold : Color.black, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .disabled(locked)
                        .opacity(locked ? 0.45 : 1)
                    }
                }
            }
        }
    }

    private func unlockLevel(tier: Int) -> Int {
        max(1, 3 * (tier - 1))
    }

    // MARK: 2. Minerales

    private var mineralColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("2. MINERALES").font(Theme.font(12)).foregroundStyle(Theme.textDim)
                Spacer()
                Text("\(recipe.totalMinerals)/\(CraftRecipe.maxMinerals)")
                    .font(Theme.font(12))
                    .foregroundStyle(recipe.totalMinerals >= CraftRecipe.minMinerals ? Theme.green : Theme.text)
                if !selection.isEmpty {
                    Button("✕") { selection = [:] }
                        .buttonStyle(.pixel(Theme.panelLight, size: 10))
                }
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                    ForEach(Mineral.allCases) { mineral in
                        mineralCell(mineral)
                    }
                }
                Text("Pulsa para añadir, \"−\" para quitar. Mín. \(CraftRecipe.minMinerals).")
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Mineral.allCases.filter { selection[$0, default: 0] > 0 }) { mineral in
                        let stats = mineral.buffPerUnit * Double(selection[mineral, default: 0])
                        Text("\(selection[mineral, default: 0])× \(mineral.name): \(describe(stats))")
                            .font(Theme.font(9, weight: .bold))
                            .foregroundStyle(Theme.mineralColor(mineral))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func mineralCell(_ mineral: Mineral) -> some View {
        let owned = store.profile.count(of: mineral)
        let selected = selection[mineral, default: 0]
        return VStack(spacing: 1) {
            PixelImage(image: Art.mineralImage(mineral), scale: 2.6)
            Text("\(owned - selected)")
                .font(Theme.font(10))
                .foregroundStyle(owned - selected > 0 ? Theme.text : Theme.textDim.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(selected > 0 ? Theme.mineralColor(mineral).opacity(0.3) : Theme.panel)
        .overlay(Rectangle().strokeBorder(selected > 0 ? Theme.mineralColor(mineral) : Color.black, lineWidth: 2))
        .overlay(alignment: .bottomLeading) {
            if selected > 0 {
                Button { remove(mineral) } label: {
                    Text("−")
                        .font(Theme.font(11, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Theme.red)
                }
                .buttonStyle(.plain)
                .offset(x: -3, y: 3)
            }
        }
        .overlay(alignment: .topTrailing) {
            if selected > 0 {
                Text("\(selected)")
                    .font(Theme.font(9, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 3)
                    .background(Theme.gold)
                    .offset(x: 3, y: -3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { add(mineral) }
        .onLongPressGesture(minimumDuration: 0.3) { remove(mineral) }
    }

    private func add(_ mineral: Mineral) {
        errorMessage = nil
        guard recipe.totalMinerals < CraftRecipe.maxMinerals,
              selection[mineral, default: 0] < store.profile.count(of: mineral) else { return }
        selection[mineral, default: 0] += 1
    }

    private func remove(_ mineral: Mineral) {
        guard let current = selection[mineral], current > 0 else { return }
        selection[mineral] = current > 1 ? current - 1 : nil
    }

    private func describe(_ stats: Stats) -> String {
        stats.entries.map { "\($0.kind.formatBonus($0.value)) \($0.kind.shortName)" }.joined(separator: " ")
    }

    // MARK: 3. Resultado

    private var resultColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("3. RESULTADO").font(Theme.font(12)).foregroundStyle(Theme.textDim)
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        PixelImage(image: Art.itemImage(icon: blueprint.icon), scale: 3)
                        Text(recipe.dominantMineral.map { "\(blueprint.name) de \($0.name)" } ?? blueprint.name)
                            .font(Theme.font(11, weight: .black))
                            .foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("Con calidad Normal (x1.0):")
                        .font(Theme.font(9, weight: .bold))
                        .foregroundStyle(Theme.textDim)
                    StatLines(stats: recipe.stats(multiplier: 1), fontSize: 10)

                    Text("RULETA · Suerte +\(Int(recipe.luck * 100))%")
                        .font(Theme.font(10))
                        .foregroundStyle(Theme.gold)
                        .padding(.top, 2)
                    OddsTable(luck: recipe.luck)
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.red)
            }
            Button {
                forge()
            } label: {
                HStack(spacing: 4) {
                    Text("⚒ FORJAR")
                    PixelImage(image: Art.coin, scale: 1.5)
                    Text("\(recipe.goldCost)")
                }
            }
            .buttonStyle(.pixel(Theme.orange, text: .black, size: 13))
        }
    }

    private func forge() {
        if let error = store.profile.validate(recipe) {
            errorMessage = error.message
            return
        }
        do {
            let luck = recipe.luck
            let result = try store.craft(recipe)
            selection = [:]
            pending = (result, luck)
        } catch let error as CraftError {
            errorMessage = error.message
        } catch {
            errorMessage = "No se pudo forjar"
        }
    }
}

/// Probabilidades de cada casilla de la ruleta.
private struct OddsTable: View {
    let luck: Double

    var body: some View {
        let probs = Roulette.probabilities(luck: luck)
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(Roulette.segments.enumerated()), id: \.element.id) { index, segment in
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(RouletteView.color(for: index))
                        .frame(width: 9, height: 9)
                        .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 1))
                    Text("\(segment.name) x\(segment.multiplier, specifier: "%.1f")")
                        .font(Theme.font(9, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Spacer(minLength: 0)
                    Text("\(Int((probs[index] * 100).rounded()))%")
                        .font(Theme.font(9))
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
    }
}
