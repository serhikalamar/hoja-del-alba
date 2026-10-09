import GameCore
import SwiftUI

/// La forja del enano (en el pueblo y entre oleadas de la arena): el herrero te mira desde detrás del mostrador,
/// con la fragua encendida detrás. Pestañas grandes para el dedo: tienda, ritual, armería y vender.
struct ForgeShopView<Info: View>: View {
    enum Tab: String, CaseIterable {
        case shop = "⚒ TIENDA"
        case ritual = "✦ RITUAL"
        case armory = "⛨ ARMERÍA"
        case sell = "◈ VENDER"
    }

    @Environment(GameStore.self) private var store
    let shop: ShopModel?
    let hp: Double
    let maxHP: Double
    /// Botón principal (salir de la forja / siguiente oleada).
    let primaryTitle: String
    let primaryAction: () -> Void
    /// Frases del bocadillo del herrero (en el pueblo dependen de la historia; en la arena, las de siempre).
    var bubbles: [String] = ValdemarDialogue.smithBubbles
    /// Información de la cabecera (oleada superada, nivel de la forja…).
    @ViewBuilder let info: Info

    @State private var tab: Tab = Self.initialTab
    /// Frase del bocadillo (vacía hasta que aparece: entonces sale una de `bubbles`).
    @State private var line = ""
    @State private var reaction: DwarfSmithArt.Pose?
    @State private var reactionID = 0

    /// Pestaña al abrir (en Debug se puede elegir con `-pestaña`).
    private static var initialTab: Tab {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-pestaña"), i + 1 < args.count,
           let tab = Tab.allCases.first(where: { $0.rawValue.lowercased().contains(args[i + 1]) }) {
            return tab
        }
        #endif
        return .shop
    }

    private var randomBubble: String {
        bubbles.randomElement() ?? ValdemarDialogue.smithBubbles[0]
    }

    private static var thanks: [String] {
        ["¡Buena elección!", "¡Eso sí es acero!", "Cuídamela, ¿eh?", "¡Ja! Te durará cien batallas.", "Vuelve cuando quieras."]
    }

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let full = CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                              height: proxy.size.height + insets.top + insets.bottom)
            let dwarfArea = ForgeShopLayout.dwarfAreaWidth(screenWidth: proxy.size.width)
            let showsDwarf = tab == .shop
            HStack(alignment: .top, spacing: 0) {
                if showsDwarf {
                    dwarfCorner(width: dwarfArea, height: proxy.size.height + insets.bottom)
                        .frame(width: dwarfArea, height: proxy.size.height, alignment: .top)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                VStack(alignment: .leading, spacing: 8) {
                    header
                    tabBar
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(.leading, showsDwarf ? 4 : 16)
                .padding(.trailing, 14)
                .padding(.vertical, 10)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .animation(.easeOut(duration: 0.2), value: tab)
            // El fondo no cuenta para el tamaño: ocupa toda la pantalla (también bajo la muesca).
            .background(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    backdrop(full: full, dwarfCenter: insets.leading + dwarfArea / 2)
                    if !showsDwarf {
                        Color.black.opacity(0.72).frame(width: full.width, height: full.height)
                    }
                }
                .offset(x: -insets.leading, y: -insets.top)
                .allowsHitTesting(false)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Escenario

    /// Fondo de la forja a 3 puntos por pixel de arte, del tamaño de la pantalla entera.
    private func backdrop(full: CGSize, dwarfCenter: CGFloat) -> some View {
        let s = ForgeShopLayout.scale
        let w = max(40, Int((full.width / s).rounded(.up))), h = max(40, Int((full.height / s).rounded(.up)))
        let focus = Int(dwarfCenter / s)
        let image = ArtCache.image("forge.backdrop.\(w)x\(h).\(focus)", grid: { ForgeBackdropArt.backdrop(width: w, height: h, focusX: focus) })
        return ZStack(alignment: .topLeading) {
            PixelImage(image: image, scale: s)
            TimelineView(.periodic(from: .now, by: 0.15)) { context in
                let frame = Int(context.date.timeIntervalSinceReferenceDate / 0.15) % ForgeBackdropArt.emberFrames
                PixelImage(image: ArtCache.image("forge.embers.\(w)x\(h).\(focus).\(frame)", grid: {
                    ForgeBackdropArt.embers(width: w, height: h, focusX: focus, frame: frame)
                }), scale: s)
            }
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
        .clipped()
    }

    /// El enano de frente detrás del mostrador, con su bocadillo.
    private func dwarfCorner(width: CGFloat, height: CGFloat) -> some View {
        let s = ForgeShopLayout.scale
        let counterArtWidth = Int((width / s).rounded(.up))
        let counter = ArtCache.image("forge.counter.\(counterArtWidth)", grid: { ForgeBackdropArt.counter(width: counterArtWidth) })
        let counterHeight = CGFloat(ForgeBackdropArt.counterHeight) * s
        return ZStack(alignment: .bottom) {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                PixelImage(image: dwarfImage(at: context.date), scale: s)
                    .offset(y: -counterHeight + CGFloat(DwarfSmithArt.counterLine) * s)
            }
            PixelImage(image: counter, scale: s)
                .frame(width: width, height: counterHeight, alignment: .leading)
                .clipped()
            VStack {
                if !line.isEmpty {
                    Text(line)
                        .font(Theme.font(12, weight: .bold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(hex: 0xF4ECD8))
                        .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        .id(line)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(duration: 0.25), value: line)
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { react(.talk, say: randomBubble) }
        .onAppear { if line.isEmpty { line = randomBubble } }
    }

    /// Pose del enano: reacciona a lo que haces; si no, respira, parpadea y a veces golpea el yunque.
    private func dwarfImage(at date: Date) -> CGImage {
        let t = date.timeIntervalSinceReferenceDate
        let pose: DwarfSmithArt.Pose
        if let reaction {
            if reaction == .happy || reaction == .talk {
                pose = Int(t * 4) % 2 == 0 ? reaction : (reaction == .happy ? .hammerUp : .idle0)
            } else {
                pose = reaction
            }
        } else {
            let cycle = Int(t * 4) % 40
            switch cycle {
            case 13: pose = .blink
            case 30, 32, 34: pose = .hammerUp
            case 31, 33, 35: pose = .hammerDown
            default: pose = cycle % 4 < 2 ? .idle0 : .idle1
            }
        }
        return ArtCache.image("dwarfSmith.\(pose)", grid: { DwarfSmithArt.grid(pose) })
    }

    private func react(_ pose: DwarfSmithArt.Pose, say text: String? = nil) {
        reactionID += 1
        let id = reactionID
        reaction = pose
        if let text { line = text }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            if reactionID == id { reaction = nil }
        }
    }

    // MARK: - Cabecera y pestañas

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                info
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                HPBar(hp: hp, maxHP: maxHP, width: 140)
            }
            Spacer(minLength: 4)
            GoldLabel(amount: store.profile.gold, size: 18)
            if tab == .shop, let shop {
                Button {
                    shop.reroll()
                    react(.talk, say: "¡Mira lo que tengo en la trastienda!")
                } label: {
                    HStack(spacing: 4) {
                        Text("↻")
                        PixelImage(image: Art.coin, scale: 1.5)
                        Text("\(shop.rerollCost)")
                    }
                }
                .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 46))
                .disabled(store.profile.gold < shop.rerollCost)
            }
            Button(primaryTitle, action: primaryAction)
                .buttonStyle(.pixel(Theme.green, text: .black, size: 16, minHeight: 46))
        }
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases, id: \.self) { item in
                Button { tab = item } label: {
                    Text(item.rawValue).frame(maxWidth: .infinity)
                }
                .buttonStyle(.pixel(tab == item ? Theme.gold : Theme.panelLight.opacity(0.92),
                                    text: tab == item ? .black : Theme.text, size: 13, minHeight: 46))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .shop:
            if let shop { offers(shop) }
        case .ritual:
            RitualForgeView(showsBackButton: false)
        case .armory:
            ArmoryView()
        case .sell:
            InventoryView()
        }
    }

    // MARK: - Tienda

    /// Cartas en fila: caben enteras en el ancho visible y, si hay más, se desliza carta a carta
    /// (sin cartas cortadas por el borde).
    private func offers(_ shop: ShopModel) -> some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 10
            let visible = max(1, Int((proxy.size.width + spacing) / (ForgeOfferCard.minWidth + spacing)))
            let cardWidth = (proxy.size.width - CGFloat(visible - 1) * spacing) / CGFloat(visible)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(shop.offers) { offer in
                        ForgeOfferCard(shop: shop, offer: offer, width: cardWidth) {
                            react(.happy, say: Self.thanks.randomElement()!)
                        }
                    }
                }
                .padding(.vertical, 2)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

/// Carta grande de una oferta: se compra tocando el botón de abajo (ancho completo, cómodo con el dedo).
private struct ForgeOfferCard: View {
    @Environment(GameStore.self) private var store
    let shop: ShopModel
    let offer: ShopOffer
    var width: CGFloat = minWidth
    let onBuy: () -> Void

    static let minWidth: CGFloat = 172

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            switch offer.kind {
            case .part(let part):
                HStack(alignment: .top) {
                    PixelImage(image: Art.partImage(part), scale: 2.6)
                        .frame(width: 50, height: 52)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(part.slot.name.uppercased()).font(Theme.font(9)).foregroundStyle(Theme.textDim)
                            .multilineTextAlignment(.trailing)
                        Text("T\(part.tier)").font(Theme.font(13)).foregroundStyle(Theme.gold)
                        if store.profile.partCount(part.id) > 0 {
                            Text("Tienes \(store.profile.partCount(part.id))").font(Theme.font(9)).foregroundStyle(Theme.green)
                        }
                    }
                }
                Text(part.name)
                    .font(Theme.font(12, weight: .black))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                ElementChips(elements: part.elements)
                StatLines(stats: part.stats, fontSize: 11)
            case .equipment(let item):
                HStack(alignment: .top) {
                    PixelImage(image: Art.itemImage(item), scale: 3.4)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.rarity.name.uppercased()).font(Theme.font(10)).foregroundStyle(Theme.rarityColor(item.rarity))
                        Text(item.slot.name).font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.textDim)
                        CompareBadge(item: item, equipped: store.profile.equipped(item.slot))
                    }
                }
                Text(item.name)
                    .font(Theme.font(13, weight: .black))
                    .foregroundStyle(Theme.rarityColor(item.rarity))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                StatLines(stats: item.stats, fontSize: 11)
            case .potion(let fraction):
                PixelImage(image: Art.potion, scale: 3.4)
                Text("Poción de vida").font(Theme.font(14, weight: .black)).foregroundStyle(Theme.text)
                Text("Cura un \(Int(fraction * 100))% de la vida al momento")
                    .font(Theme.font(11, weight: .bold))
                    .foregroundStyle(Theme.green)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            footer
        }
        .padding(9)
        .frame(width: width, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .top)
        .pixelPanel(fill: offer.sold ? Theme.panel.opacity(0.75) : Theme.panel.opacity(0.94))
    }

    @ViewBuilder
    private var footer: some View {
        if offer.sold {
            switch offer.kind {
            case .equipment(let item):
                if let owned = store.profile.inventory.first(where: { $0.id == item.id }), !store.profile.isEquipped(owned) {
                    Button { store.equip(owned) } label: { Text("EQUIPAR").frame(maxWidth: .infinity) }
                        .buttonStyle(.pixel(Theme.blue, text: .black, size: 14, minHeight: 46))
                } else {
                    soldLabel("✓ EQUIPADA")
                }
            case .potion: soldLabel("USADA")
            case .part: soldLabel("✓ COMPRADA")
            }
        } else {
            Button {
                shop.buy(offer)
                if shop.offers.first(where: { $0.id == offer.id })?.sold == true { onBuy() }
            } label: {
                HStack(spacing: 5) {
                    PixelImage(image: Art.coin, scale: 2)
                    Text("\(offer.price)")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pixel(Theme.gold, text: .black, size: 16, minHeight: 48))
            .disabled(!shop.canAfford(offer) || (isPotion && !shop.needsHealing()))
        }
    }

    private var isPotion: Bool {
        if case .potion = offer.kind { return true }
        return false
    }

    private func soldLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(14))
            .foregroundStyle(Theme.green)
            .frame(maxWidth: .infinity, minHeight: 46)
    }
}
