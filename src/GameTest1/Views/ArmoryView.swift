import GameCore
import SwiftUI

/// Armería del enano: forja de cascos, petos, guantes y botas con diseño, material, tinte y minerales.
/// La vista previa muestra al personaje con la pieza puesta.
struct ArmoryView: View {
    @Environment(GameStore.self) private var store
    @State private var slot: EquipmentSlot = .helmet
    @State private var styleID = "helm.knight"
    @State private var materialID = "copper"
    @State private var dye: UInt32 = ArmorCatalog.dyes[0]
    @State private var minerals: [Mineral: Int] = [:]
    @State private var pending: (result: CraftResult, luck: Double)?
    @State private var errorMessage: String?

    private var style: ArmorStyle { ArmorCatalog.style(styleID) ?? ArmorCatalog.styles(for: slot)[0] }

    private var materials: [PartMaterial] { style.materialKind.materials }

    private var recipe: ArmorRecipe {
        ArmorRecipe(styleID: style.id, materialID: materialID, dye: dye, minerals: minerals)
    }

    /// El personaje con su equipo actual y la pieza que se está diseñando.
    private var previewLook: HeroLook {
        var look = HeroLook(profile: store.profile)
        let palette = ArmorCatalog.material(materialID)?.palette ?? materials[0].palette
        look.gear[slot] = GearLook(styleID: style.id, material: palette, dye: dye)
        return look
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            designColumn.frame(width: 180)
            previewColumn.frame(maxWidth: .infinity)
            materialColumn.frame(width: 190)
        }
        .overlay {
            if let pending {
                RitualRevealView(result: pending.result, luck: pending.luck) { action in
                    let item = pending.result.item
                    self.pending = nil
                    if action == .equip { store.equip(item) }
                }
            }
        }
        .onAppear(perform: fixSelection)
    }

    // MARK: Diseño

    private var designColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
                ForEach(EquipmentSlot.gear) { s in
                    Button {
                        slot = s
                        styleID = ArmorCatalog.styles(for: s)[0].id
                        fixSelection()
                    } label: {
                        Text(s.name.uppercased()).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.pixel(slot == s ? Theme.gold : Theme.panelLight, text: slot == s ? .black : Theme.text, size: 11, minHeight: 36))
                }
            }
            Text("DISEÑO").font(Theme.font(10)).foregroundStyle(Theme.textDim)
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(ArmorCatalog.styles(for: slot)) { s in
                        Button {
                            styleID = s.id
                            fixSelection()
                        } label: {
                            HStack(spacing: 6) {
                                let palette = s.materialKind.materials[min(materials.count - 1, 2)].palette
                                PixelImage(image: HeroArt.gearIcon(GearLook(styleID: s.id, material: palette, dye: dye), slot: s.slot).makeCGImage(), scale: 2.2)
                                    .frame(width: 30, height: 30)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(s.name).font(Theme.font(10, weight: .black)).foregroundStyle(Theme.text)
                                    Text(materialKindName(s.materialKind)).font(Theme.font(8, weight: .bold)).foregroundStyle(Theme.textDim)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(4)
                            .background(s.id == styleID ? Theme.panelLight : Theme.panel)
                            .overlay(Rectangle().strokeBorder(s.id == styleID ? Theme.gold : Color.black, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func materialKindName(_ kind: ArmorMaterialKind) -> String {
        switch kind {
        case .metal: "Metal"
        case .leather: "Cuero"
        case .cloth: "Tela"
        }
    }

    // MARK: Vista previa

    private var previewColumn: some View {
        VStack(spacing: 6) {
            Text(recipe.itemName.uppercased())
                .font(Theme.font(12, weight: .black))
                .foregroundStyle(Theme.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HeroPreview(look: previewLook, weapon: store.profile.equippedWeapon, scale: 2.6)
                .frame(height: 120)
            StatLines(stats: recipe.stats(multiplier: 1), fontSize: 9)
            Text("Calidad normal ×1.0 · la ruleta decide")
                .font(Theme.font(8, weight: .bold))
                .foregroundStyle(Theme.textDim)
            OddsBar(luck: recipe.luck)
        }
    }

    // MARK: Material, tinte y minerales

    private var materialColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MATERIAL").font(Theme.font(10)).foregroundStyle(Theme.textDim)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                ForEach(materials) { m in
                    let locked = m.tier > store.profile.maxArmorTier
                    Button { materialID = m.id } label: {
                        VStack(spacing: 1) {
                            HStack(spacing: 0) {
                                ForEach(Array(m.palette.enumerated()), id: \.offset) { _, c in Rectangle().fill(Color(hex: c)) }
                            }
                            .frame(height: 8)
                            Text(locked ? "🔒" : m.name).font(Theme.font(7, weight: .black)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .padding(3)
                        .background(m.id == materialID ? Theme.panelLight : Theme.panel)
                        .overlay(Rectangle().strokeBorder(m.id == materialID ? Theme.gold : Color.black, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .disabled(locked)
                    .opacity(locked ? 0.45 : 1)
                }
            }
            Text("TINTE").font(Theme.font(10)).foregroundStyle(Theme.textDim)
            DyePicker(selection: $dye)
            Text("MINERALES \(recipe.totalMinerals)/\(ArmorRecipe.maxMinerals)").font(Theme.font(10)).foregroundStyle(Theme.textDim)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 5), spacing: 3) {
                ForEach(Mineral.allCases) { mineral in
                    mineralCell(mineral)
                }
            }
            Spacer(minLength: 0)
            if let errorMessage {
                Text(errorMessage).font(Theme.font(9, weight: .bold)).foregroundStyle(Theme.red)
            }
            Button { forge() } label: {
                HStack(spacing: 4) {
                    Text("⚒ FORJAR")
                    PixelImage(image: Art.coin, scale: 1.5)
                    Text("\(recipe.goldCost)")
                }
            }
            .buttonStyle(.pixel(Theme.orange, text: .black, size: 13))
        }
    }

    private func mineralCell(_ mineral: Mineral) -> some View {
        let owned = store.profile.count(of: mineral)
        let selected = minerals[mineral, default: 0]
        return Button {
            guard recipe.totalMinerals < ArmorRecipe.maxMinerals, selected < owned else { return }
            minerals[mineral, default: 0] += 1
        } label: {
            VStack(spacing: 0) {
                PixelImage(image: Art.mineralImage(mineral), scale: 2)
                Text("\(owned - selected)").font(Theme.font(8)).foregroundStyle(owned - selected > 0 ? Theme.text : Theme.textDim.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .background(selected > 0 ? Theme.mineralColor(mineral).opacity(0.3) : Color.black.opacity(0.35))
            .overlay(Rectangle().strokeBorder(selected > 0 ? Theme.mineralColor(mineral) : Color.black, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if selected > 0 {
                Button {
                    minerals[mineral] = selected > 1 ? selected - 1 : nil
                } label: {
                    Text("\(selected)−").font(Theme.font(8, weight: .black)).foregroundStyle(.white).padding(.horizontal, 2).background(Theme.red)
                }
                .buttonStyle(.plain)
                .offset(x: 3, y: -4)
            }
        }
    }

    /// Si el material elegido no vale para este diseño (o está bloqueado), usa el mejor disponible.
    private func fixSelection() {
        let available = style.materialKind.materials.filter { $0.tier <= store.profile.maxArmorTier }
        if !available.contains(where: { $0.id == materialID }) {
            materialID = available.last?.id ?? style.materialKind.materials[0].id
        }
    }

    private func forge() {
        if let error = store.profile.validate(recipe) {
            errorMessage = error.message
            return
        }
        do {
            let luck = recipe.luck
            let result = try store.craftArmor(recipe)
            minerals = [:]
            errorMessage = nil
            pending = (result, luck)
        } catch let error as CraftError {
            errorMessage = error.message
        } catch {
            errorMessage = "No se ha podido forjar"
        }
    }
}

/// Muestrario de tintes.
struct DyePicker: View {
    @Binding var selection: UInt32

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(18), spacing: 3), count: 6), alignment: .leading, spacing: 3) {
            ForEach(ArmorCatalog.dyes, id: \.self) { color in
                Rectangle()
                    .fill(Color(hex: color))
                    .frame(width: 18, height: 18)
                    .overlay(Rectangle().strokeBorder(color == selection ? Theme.gold : Color.black, lineWidth: color == selection ? 3 : 1))
                    .onTapGesture { selection = color }
            }
        }
    }
}
