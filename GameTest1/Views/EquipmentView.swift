import GameCore
import SwiftUI

struct EquipmentView: View {
    @Environment(GameStore.self) private var store
    @State private var slot: EquipmentSlot = .weapon

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            characterPanel.frame(width: 200)
            inventoryPanel
        }
    }

    private var characterPanel: some View {
        let profile = store.profile
        let stats = profile.totalStats
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 4) {
                PixelImage(image: Art.knightImage(armorIcon: profile.equippedArmor?.icon ?? "armor_tunic"), scale: 4.5)
                PixelImage(image: Art.itemImage(icon: profile.equippedWeapon?.icon ?? "sword_wood"), scale: 3.5)
            }
            .frame(maxWidth: .infinity)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(StatKind.allCases, id: \.self) { kind in
                        HStack {
                            Text(kind.shortName)
                                .font(Theme.font(10, weight: .bold))
                                .foregroundStyle(Theme.textDim)
                            Spacer()
                            Text(kind.formatValue(stats[kind]))
                                .font(Theme.font(10))
                                .foregroundStyle(Theme.text)
                        }
                    }
                }
            }
        }
        .padding(10)
        .pixelPanel()
    }

    private var inventoryPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(EquipmentSlot.allCases, id: \.self) { s in
                    Button(s == .weapon ? "ARMAS" : "ARMADURAS") { slot = s }
                        .buttonStyle(.pixel(slot == s ? Theme.gold : Theme.panelLight,
                                            text: slot == s ? .black : Theme.text, size: 12))
                }
                Spacer()
            }
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(items) { item in
                        ItemRow(item: item)
                    }
                }
                .padding(.trailing, 6)
            }
        }
    }

    private var items: [Item] {
        let profile = store.profile
        return profile.inventory
            .filter { $0.slot == slot }
            .sorted { a, b in
                let ae = profile.isEquipped(a), be = profile.isEquipped(b)
                if ae != be { return ae }
                return a.powerScore > b.powerScore
            }
    }
}

private struct ItemRow: View {
    @Environment(GameStore.self) private var store
    let item: Item

    var body: some View {
        let equipped = store.profile.isEquipped(item)
        HStack(spacing: 8) {
            PixelImage(image: Art.itemImage(icon: item.icon), scale: 2.6)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(Theme.font(11, weight: .black))
                        .foregroundStyle(Theme.rarityColor(item.rarity))
                        .lineLimit(1)
                    if let quality = item.qualityName, let mult = item.qualityMultiplier {
                        Text("⚒ \(quality) x\(mult, specifier: "%.1f")")
                            .font(Theme.font(9, weight: .bold))
                            .foregroundStyle(Theme.gold)
                    }
                }
                Text(item.stats.entries.map { "\($0.kind.formatBonus($0.value)) \($0.kind.shortName)" }.joined(separator: "  "))
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.green)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            CompareBadge(item: item, equipped: store.profile.equipped(item.slot))
            if equipped {
                Text("EQUIPADO")
                    .font(Theme.font(10))
                    .foregroundStyle(Theme.green)
            } else {
                Button("EQUIPAR") { store.equip(item) }
                    .buttonStyle(.pixel(Theme.blue, text: .black, size: 10))
                Button {
                    store.sell(item)
                } label: {
                    HStack(spacing: 3) {
                        Text("VENDER")
                        PixelImage(image: Art.coin, scale: 1.3)
                        Text("\(item.sellPrice)")
                    }
                }
                .buttonStyle(.pixel(Theme.panelLight, size: 10))
            }
        }
        .padding(8)
        .background(equipped ? Theme.panelLight : Theme.panel)
        .overlay(Rectangle().strokeBorder(equipped ? Theme.green : Color.black, lineWidth: 2))
    }
}
