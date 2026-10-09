import GameCore
import SwiftUI

/// Inventario completo: personaje a la izquierda y pestañas a la derecha.
struct InventoryView: View {
    enum Tab: String, CaseIterable {
        case weapons = "ARMAS"
        case armor = "ARMADURAS"
        case parts = "PIEZAS"
        case minerals = "MINERALES"
        case abilities = "HABILIDADES"
    }

    @Environment(GameStore.self) private var store
    /// En la tienda se puede vender y dibujar el arma; en la pausa solo revisar y cambiar de equipo.
    var allowsTrading = true
    @State private var tab: Tab = .weapons
    @State private var editingItemID: UUID?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            characterPanel.frame(width: 210)
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Tab.allCases, id: \.self) { t in
                            Button(t.rawValue) { tab = t }
                                .buttonStyle(.pixel(tab == t ? Theme.gold : Theme.panelLight, text: tab == t ? .black : Theme.text, size: 10))
                        }
                    }
                    .padding(.bottom, 4)
                }
                ScrollView {
                    switch tab {
                    case .weapons: itemList([.weapon])
                    case .armor: itemList(EquipmentSlot.gear)
                    case .parts: partsList
                    case .minerals: mineralsList
                    case .abilities: abilitiesList
                    }
                }
            }
        }
        .overlay {
            if let id = editingItemID, let item = store.item(id) {
                PixelEditorView(item: item) { editingItemID = nil }
            }
        }
    }

    // MARK: - Personaje

    private var characterPanel: some View {
        let profile = store.profile
        let stats = profile.totalStats
        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 6) {
                HeroPreview(look: HeroLook(profile: profile), weapon: profile.equippedWeapon, scale: 2.2)
                VStack(spacing: 4) {
                    ForEach(EquipmentSlot.allCases) { slot in
                        EquipmentSlotCell(slot: slot)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            Text("\((profile.name ?? "Héroe").uppercased()) · NV \(profile.characterLevel) · \(profile.race.name.uppercased())")
                .font(Theme.font(12, weight: .black))
                .foregroundStyle(Theme.gold)
            if let ability = profile.activeAbility {
                Text("✦ \(ability.name)").font(Theme.font(10, weight: .black)).foregroundStyle(Color(hex: ability.elements.first?.color ?? 0xFFFFFF))
                Text(ability.description).font(Theme.font(8, weight: .bold)).foregroundStyle(Theme.textDim).fixedSize(horizontal: false, vertical: true)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(StatKind.allCases, id: \.self) { kind in
                        HStack {
                            Text(kind.shortName).font(Theme.font(9, weight: .bold)).foregroundStyle(Theme.textDim)
                            Spacer()
                            Text(kind.formatValue(stats[kind])).font(Theme.font(9)).foregroundStyle(Theme.text)
                        }
                    }
                }
            }
        }
        .padding(9)
        .pixelPanel()
    }

    // MARK: - Objetos

    private func itemList(_ slots: [EquipmentSlot]) -> some View {
        let profile = store.profile
        let items = profile.inventory
            .filter { slots.contains($0.slot) }
            .sorted { a, b in
                let ae = profile.isEquipped(a), be = profile.isEquipped(b)
                if ae != be { return ae }
                return a.powerScore > b.powerScore
            }
        return VStack(spacing: 6) {
            if slots == [.weapon] && items.count <= 1 {
                Text("Forja armas nuevas en el ritual combinando piezas.")
                    .font(Theme.font(10, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(items) { item in
                ItemRow(item: item, allowsTrading: allowsTrading) { editingItemID = item.id }
            }
        }
        .padding(.trailing, 6)
    }

    // MARK: - Piezas

    private var partsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            let total = store.profile.parts.values.reduce(0, +)
            Text("\(total) piezas · \(PartCatalog.all.count) tipos en el mundo")
                .font(Theme.font(10, weight: .bold))
                .foregroundStyle(Theme.textDim)
            ForEach(PartSlot.allCases) { slot in
                let parts = store.profile.ownedParts(slot)
                Text(slot.name.uppercased()).font(Theme.font(11, weight: .black)).foregroundStyle(Theme.gold)
                if parts.isEmpty {
                    Text("Ninguna").font(Theme.font(9, weight: .bold)).foregroundStyle(Theme.textDim)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 6)], spacing: 6) {
                    ForEach(parts) { part in
                        VStack(alignment: .leading, spacing: 2) {
                            PartRow(part: part, count: store.profile.partCount(part.id))
                            Text(part.stats.entries.map { "\($0.kind.formatBonus($0.value)) \($0.kind.shortName)" }.joined(separator: "  "))
                                .font(Theme.font(8, weight: .bold))
                                .foregroundStyle(Theme.green)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(.trailing, 6)
    }

    // MARK: - Minerales

    private var mineralsList: some View {
        VStack(spacing: 4) {
            ForEach(Mineral.allCases) { mineral in
                HStack(spacing: 8) {
                    PixelImage(image: Art.mineralImage(mineral), scale: 3)
                    Text(mineral.name).font(Theme.font(11, weight: .black)).foregroundStyle(Theme.mineralColor(mineral))
                        .frame(width: 90, alignment: .leading)
                    Text("×\(store.profile.count(of: mineral))").font(Theme.font(11)).foregroundStyle(Theme.text)
                        .frame(width: 44, alignment: .leading)
                    Text("\(mineral.dropPercent, specifier: "%g")%").font(Theme.font(9)).foregroundStyle(Theme.textDim)
                        .frame(width: 40, alignment: .leading)
                    Text(mineral.buffPerUnit.entries.map { "\($0.kind.formatBonus($0.value)) \($0.kind.shortName)" }.joined(separator: " "))
                        .font(Theme.font(9, weight: .bold))
                        .foregroundStyle(Theme.green)
                    Spacer()
                }
                .padding(5)
                .background(Theme.panel)
                .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 2))
            }
        }
        .padding(.trailing, 6)
    }

    // MARK: - Habilidades

    private var abilitiesList: some View {
        let discovered = store.profile.discoveredAbilities
        return VStack(alignment: .leading, spacing: 5) {
            Text("Descubiertas: \(discovered.count)/\(AbilityBook.all.count). Combina elementos en el ritual para descubrir más.")
                .font(Theme.font(10, weight: .bold))
                .foregroundStyle(Theme.textDim)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 6)], spacing: 6) {
                ForEach(AbilityBook.all) { ability in
                    let known = discovered.contains(ability.id)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(known ? "✦ \(ability.name)" : "✦ ???")
                            .font(Theme.font(10, weight: .black))
                            .foregroundStyle(known ? Color(hex: ability.elements.first?.color ?? 0xFFFFFF) : Theme.textDim)
                        Text(known ? ability.description : "Habilidad secreta sin descubrir.")
                            .font(Theme.font(8, weight: .bold))
                            .foregroundStyle(known ? Theme.text : Theme.textDim.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                        if known { ElementChips(elements: ability.elements, fontSize: 7) }
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
                    .background(known ? Color(hex: 0x2A1640) : Theme.panel)
                    .overlay(Rectangle().strokeBorder(known ? Color(hex: 0xC879F2) : Color.black, lineWidth: 2))
                }
            }
        }
        .padding(.trailing, 6)
    }
}

private struct ItemRow: View {
    @Environment(GameStore.self) private var store
    let item: Item
    let allowsTrading: Bool
    let onDraw: () -> Void
    @State private var showDyes = false

    var body: some View {
        let equipped = store.profile.isEquipped(item)
        HStack(spacing: 8) {
            PixelImage(image: Art.itemImage(item), scale: item.partIDs != nil ? 1.6 : 2.6)
                .frame(width: 34, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(Theme.font(11, weight: .black))
                        .foregroundStyle(Theme.rarityColor(item.rarity))
                        .lineLimit(1)
                    if let quality = item.qualityName, let mult = item.qualityMultiplier {
                        Text("\(quality) ×\(mult, specifier: "%.1f")")
                            .font(Theme.font(8, weight: .bold))
                            .foregroundStyle(Theme.gold)
                    }
                }
                AbilityTag(ability: item.ability, fontSize: 9)
                Text(item.stats.entries.map { "\($0.kind.formatBonus($0.value)) \($0.kind.shortName)" }.joined(separator: "  "))
                    .font(Theme.font(8, weight: .bold))
                    .foregroundStyle(Theme.green)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            CompareBadge(item: item, equipped: store.profile.equipped(item.slot))
            if allowsTrading, item.partIDs != nil {
                Button("✎") { onDraw() }
                    .buttonStyle(.pixel(Color(hex: 0xC879F2), text: .black, size: 11))
            }
            if item.styleID != nil {
                Button("🎨") { showDyes.toggle() }
                    .buttonStyle(.pixel(Theme.panelLight, size: 11))
                    .popover(isPresented: $showDyes) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TEÑIR").font(Theme.font(11, weight: .black)).foregroundStyle(Theme.gold)
                            DyePicker(selection: Binding(get: { UInt32(item.dye ?? 0) }, set: { store.setDye($0, for: item) }))
                        }
                        .padding(10)
                        .background(Theme.panel)
                    }
            }
            if equipped {
                if item.slot != .weapon {
                    Button("QUITAR") { store.unequip(item.slot) }
                        .buttonStyle(.pixel(Theme.panelLight, size: 9))
                }
                Text("EQUIPADO").font(Theme.font(9)).foregroundStyle(Theme.green)
            } else {
                Button("EQUIPAR") { store.equip(item) }
                    .buttonStyle(.pixel(Theme.blue, text: .black, size: 11, minHeight: 36))
                if allowsTrading { Button {
                    store.sell(item)
                } label: {
                    HStack(spacing: 3) {
                        PixelImage(image: Art.coin, scale: 1.2)
                        Text("\(item.sellPrice)")
                    }
                }
                .buttonStyle(.pixel(Theme.panelLight, size: 11, minHeight: 36)) }
            }
        }
        .padding(6)
        .background(equipped ? Theme.panelLight : Theme.panel)
        .overlay(Rectangle().strokeBorder(equipped ? Theme.green : Color.black, lineWidth: 2))
    }
}

/// Hueco de equipo del personaje (arma, casco, peto, guantes, botas).
private struct EquipmentSlotCell: View {
    @Environment(GameStore.self) private var store
    let slot: EquipmentSlot

    var body: some View {
        let item = store.profile.equipped(slot)
        ZStack {
            Rectangle().fill(Color.black.opacity(0.45))
            if let item {
                PixelImage(image: Art.itemImage(item), scale: item.partIDs != nil ? 1 : 1.8)
            } else {
                Text(slot.name.prefix(1)).font(Theme.font(12, weight: .black)).foregroundStyle(Theme.textDim.opacity(0.5))
            }
        }
        .frame(width: 30, height: 30)
        .overlay(Rectangle().strokeBorder(item.map { Theme.rarityColor($0.rarity) } ?? Theme.border.opacity(0.4), lineWidth: 2))
        .help(item?.name ?? "\(slot.name): vacío")
    }
}
