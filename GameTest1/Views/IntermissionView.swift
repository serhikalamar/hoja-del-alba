import GameCore
import SwiftUI

/// Pantalla entre rondas: tienda, forja y equipo.
struct IntermissionView: View {
    enum Tab: String, CaseIterable {
        case shop = "TIENDA"
        case forge = "FORJA"
        case equipment = "EQUIPO"
    }

    @Environment(GameStore.self) private var store
    let session: BattleSession
    @State private var tab: Tab = .shop

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("¡RONDA \(session.round) SUPERADA!")
                    .font(Theme.font(15, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .fixedSize(horizontal: false, vertical: true)
                GoldLabel(amount: session.lastRoundReward, prefix: "+", size: 14)
                HPBar(hp: session.hp, maxHP: session.maxHP, width: 130)
                Text("+25% vida al empezar")
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.textDim)

                ForEach(Tab.allCases, id: \.self) { item in
                    Button(item.rawValue) { tab = item }
                        .buttonStyle(.pixel(tab == item ? Theme.gold : Theme.panelLight,
                                            text: tab == item ? .black : Theme.text, size: 13))
                }
                .padding(.top, 2)

                Spacer(minLength: 0)
                Button("RONDA \(session.round + 1) ▶") { session.startNextRound() }
                    .buttonStyle(.pixel(Theme.green, text: .black, size: 15))
            }
            .frame(width: 170, alignment: .leading)

            Group {
                switch tab {
                case .shop: ShopView(session: session)
                case .forge: ForgeView()
                case .equipment: EquipmentView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.background.opacity(0.94).ignoresSafeArea())
    }
}

struct ShopView: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TIENDA").font(Theme.font(18, weight: .black)).foregroundStyle(Theme.text)
                Spacer()
                GoldLabel(amount: store.profile.gold)
                Button("↻ RENOVAR \(session.rerollCost)") { session.reroll() }
                    .buttonStyle(.pixel(Theme.panelLight, size: 11))
                    .disabled(store.profile.gold < session.rerollCost)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(session.shopOffers) { offer in
                        OfferCard(session: session, offer: offer)
                    }
                }
                .padding(.vertical, 4)
                .padding(.trailing, 8)
            }
        }
    }
}

private struct OfferCard: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession
    let offer: ShopOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            switch offer.kind {
            case .equipment(let item):
                HStack(alignment: .top) {
                    PixelImage(image: Art.itemImage(icon: item.icon), scale: 3.5)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.rarity.name.uppercased())
                            .font(Theme.font(9))
                            .foregroundStyle(Theme.rarityColor(item.rarity))
                        Text("T\(item.tier) · \(item.slot.name)")
                            .font(Theme.font(9, weight: .bold))
                            .foregroundStyle(Theme.textDim)
                        CompareBadge(item: item, equipped: store.profile.equipped(item.slot))
                    }
                }
                Text(item.name)
                    .font(Theme.font(12, weight: .black))
                    .foregroundStyle(Theme.rarityColor(item.rarity))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                StatLines(stats: item.stats, fontSize: 10)
                Spacer(minLength: 4)
                if offer.sold {
                    let owned = store.profile.inventory.first { $0.id == item.id }
                    if let owned, !store.profile.isEquipped(owned) {
                        Button("EQUIPAR") { store.equip(owned) }
                            .buttonStyle(.pixel(Theme.blue, text: .black, size: 12))
                    } else {
                        Text(owned == nil ? "VENDIDO" : "✓ EQUIPADO")
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.green)
                    }
                } else {
                    buyButton
                }
            case .potion(let fraction):
                PixelImage(image: Art.potion, scale: 3.5)
                Text("Poción de vida")
                    .font(Theme.font(12, weight: .black))
                    .foregroundStyle(Theme.text)
                Text("Cura un \(Int(fraction * 100))% de la vida al momento")
                    .font(Theme.font(10, weight: .bold))
                    .foregroundStyle(Theme.green)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if offer.sold {
                    Text("USADA").font(Theme.font(12)).foregroundStyle(Theme.textDim)
                } else {
                    buyButton.disabled(!session.canAfford(offer) || session.hp >= session.maxHP)
                }
            }
        }
        .padding(10)
        .frame(width: 150, height: 228, alignment: .topLeading)
        .pixelPanel(fill: offer.sold ? Theme.panel.opacity(0.6) : Theme.panel)
    }

    private var buyButton: some View {
        Button {
            session.buy(offer)
        } label: {
            HStack(spacing: 4) {
                PixelImage(image: Art.coin, scale: 1.6)
                Text("\(offer.price)")
            }
        }
        .buttonStyle(.pixel(Theme.gold, text: .black, size: 12))
        .disabled(!session.canAfford(offer))
    }
}
