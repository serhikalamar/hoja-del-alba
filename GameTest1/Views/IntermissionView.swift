import GameCore
import SwiftUI

/// Pantalla entre rondas: forja del enano (tienda), ritual e inventario.
struct IntermissionView: View {
    enum Tab: String, CaseIterable {
        case shop = "HERRERO"
        case ritual = "RITUAL"
        case inventory = "INVENTARIO"
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
            .frame(width: 160, alignment: .leading)

            Group {
                switch tab {
                case .shop: DwarfShopView(session: session)
                case .ritual: RitualForgeView(showsBackButton: false)
                case .inventory: InventoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.background.opacity(0.95).ignoresSafeArea())
    }
}

/// La forja del enano: el herrero vigila desde la izquierda y vende piezas.
struct DwarfShopView: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession
    @State private var line = DwarfShopView.lines.randomElement()!
    @State private var hammering = false

    static let lines = [
        "¡Acero de Valdehierro! Nada de baratijas.",
        "Una buena hoja necesita una buena guarda.",
        "Mezcla elementos... y el ritual hará el resto.",
        "Los jefes llevan piezas que ni yo sé forjar.",
        "¿Una poción? Tienes mala cara, muchacho.",
        "Obsidiana y roble... huele a magma. Je, je.",
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            dwarfCorner.frame(width: 150)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("FORJA DEL ENANO").font(Theme.font(17, weight: .black)).foregroundStyle(Theme.orange)
                    Spacer()
                    GoldLabel(amount: store.profile.gold)
                    Button("↻ \(session.rerollCost)") {
                        session.reroll()
                        line = Self.lines.randomElement()!
                    }
                    .buttonStyle(.pixel(Theme.panelLight, size: 11))
                    .disabled(store.profile.gold < session.rerollCost)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
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

    private var dwarfCorner: some View {
        VStack(spacing: 6) {
            Text(line)
                .font(Theme.font(10, weight: .bold))
                .foregroundStyle(.black)
                .padding(8)
                .background(Color(hex: 0xF4ECD8))
                .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 2))
                .fixedSize(horizontal: false, vertical: true)
            ZStack(alignment: .bottom) {
                // Brasas de la fragua detrás
                Rectangle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFF8A30).opacity(0.55), .clear], center: .center, startRadius: 4, endRadius: 80))
                    .frame(width: 150, height: 150)
                VStack(spacing: -6) {
                    PixelImage(image: Art.dwarf, scale: 3.2)
                    PixelImage(image: Art.anvil, scale: 3)
                }
                PixelImage(image: Art.smithHammer, scale: 3)
                    .rotationEffect(.degrees(hammering ? -50 : 10), anchor: .bottom)
                    .offset(x: 50, y: -48)
                    .animation(.easeInOut(duration: 0.35).repeatForever(), value: hammering)
            }
        }
        .onAppear { hammering = true }
    }
}

private struct OfferCard: View {
    @Environment(GameStore.self) private var store
    let session: BattleSession
    let offer: ShopOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            switch offer.kind {
            case .part(let part):
                HStack(alignment: .top) {
                    PixelImage(image: Art.partImage(part), scale: 2.6)
                        .frame(width: 50, height: 52)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(part.slot.name.uppercased())
                            .font(Theme.font(8))
                            .foregroundStyle(Theme.textDim)
                            .multilineTextAlignment(.trailing)
                        Text("T\(part.tier)").font(Theme.font(10)).foregroundStyle(Theme.gold)
                        if store.profile.partCount(part.id) > 0 {
                            Text("Tienes \(store.profile.partCount(part.id))").font(Theme.font(8)).foregroundStyle(Theme.green)
                        }
                    }
                }
                Text(part.name)
                    .font(Theme.font(11, weight: .black))
                    .foregroundStyle(Theme.text)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                ElementChips(elements: part.elements)
                StatLines(stats: part.stats, fontSize: 9)
                Spacer(minLength: 4)
                if offer.sold {
                    Text("✓ COMPRADA").font(Theme.font(12)).foregroundStyle(Theme.green)
                } else {
                    buyButton
                }
            case .equipment(let item):
                HStack(alignment: .top) {
                    PixelImage(image: Art.itemImage(item), scale: 3.5)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.rarity.name.uppercased()).font(Theme.font(9)).foregroundStyle(Theme.rarityColor(item.rarity))
                        Text("Armadura").font(Theme.font(9, weight: .bold)).foregroundStyle(Theme.textDim)
                        CompareBadge(item: item, equipped: store.profile.equipped(item.slot))
                    }
                }
                Text(item.name)
                    .font(Theme.font(11, weight: .black))
                    .foregroundStyle(Theme.rarityColor(item.rarity))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                StatLines(stats: item.stats, fontSize: 10)
                Spacer(minLength: 4)
                if offer.sold {
                    if let owned = store.profile.inventory.first(where: { $0.id == item.id }), !store.profile.isEquipped(owned) {
                        Button("EQUIPAR") { store.equip(owned) }
                            .buttonStyle(.pixel(Theme.blue, text: .black, size: 12))
                    } else {
                        Text("✓ EQUIPADA").font(Theme.font(12)).foregroundStyle(Theme.green)
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
        .padding(9)
        .frame(width: 138, height: 250, alignment: .topLeading)
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
