import GameCore
import SwiftUI

/// Ritual de forja: se colocan hoja, guarda y empuñadura en los altares, se ofrecen minerales
/// y se gira la ruleta. La combinación despierta una habilidad secreta.
struct RitualForgeView: View {
    @Environment(GameStore.self) private var store
    let showsBackButton: Bool

    @State private var activeSlot: PartSlot = .head
    @State private var chosen: [PartSlot: String] = [:]
    @State private var minerals: [Mineral: Int] = [:]
    @State private var pending: (result: CraftResult, luck: Double)?
    @State private var editingItemID: UUID?
    @State private var errorMessage: String?

    private var recipe: WeaponRecipe? {
        guard let head = chosen[.head], let hilt = chosen[.hilt], let grip = chosen[.grip] else { return nil }
        return WeaponRecipe(headID: head, guardID: hilt, gripID: grip, minerals: minerals)
    }

    private var chosenParts: [WeaponPart] {
        PartSlot.allCases.compactMap { chosen[$0] }.compactMap(PartCatalog.part)
    }

    var body: some View {
        VStack(spacing: 8) {
            if showsBackButton {
                HStack {
                    Button("◀ VOLVER") { store.go(to: .characterSelect) }
                        .buttonStyle(.pixel(Theme.panelLight, size: 12))
                    Text("RITUAL DE FORJA")
                        .font(Theme.font(22, weight: .black))
                        .foregroundStyle(Color(hex: 0xC879F2))
                        .padding(.leading, 8)
                    Spacer()
                    GoldLabel(amount: store.profile.gold)
                }
            }
            HStack(alignment: .top, spacing: 10) {
                partsColumn.frame(width: 172)
                ritualCircle.frame(maxWidth: .infinity, maxHeight: .infinity)
                offeringColumn.frame(width: 182)
            }
        }
        .padding(.horizontal, showsBackButton ? 16 : 0)
        .padding(.vertical, showsBackButton ? 10 : 0)
        .background(
            RadialGradient(colors: [Color(hex: 0x2A1640), Color(hex: 0x0E0A18)], center: .center, startRadius: 20, endRadius: 420)
                .ignoresSafeArea()
        )
        .overlay {
            if let pending {
                RitualRevealView(result: pending.result, luck: pending.luck) { action in
                    let itemID = pending.result.item.id
                    self.pending = nil
                    switch action {
                    case .equip: store.equip(pending.result.item)
                    case .draw:
                        store.equip(pending.result.item)
                        editingItemID = itemID
                    case .keep: break
                    }
                }
            }
        }
        .overlay {
            if let id = editingItemID, let item = store.item(id) {
                PixelEditorView(item: item) { editingItemID = nil }
            }
        }
        .onAppear(perform: pruneSelection)
    }

    // MARK: - Piezas

    private var partsColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(PartSlot.allCases) { slot in
                    Button(shortName(slot)) { activeSlot = slot }
                        .buttonStyle(.pixel(activeSlot == slot ? Color(hex: 0xC879F2) : Theme.panelLight,
                                            text: activeSlot == slot ? .black : Theme.text, size: 9))
                }
            }
            let owned = store.profile.ownedParts(activeSlot)
            if owned.isEmpty {
                Text("No tienes piezas de este tipo. Cómpralas al herrero o derrota jefes.")
                    .font(Theme.font(9, weight: .bold))
                    .foregroundStyle(Theme.textDim)
            }
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(owned) { part in
                        Button {
                            chosen[activeSlot] = chosen[activeSlot] == part.id ? nil : part.id
                            errorMessage = nil
                            if chosen[activeSlot] != nil, let next = PartSlot.allCases.first(where: { chosen[$0] == nil }) {
                                activeSlot = next
                            }
                        } label: {
                            PartRow(part: part, count: store.profile.partCount(part.id), selected: chosen[part.slot] == part.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func shortName(_ slot: PartSlot) -> String {
        switch slot {
        case .head: "HOJA"
        case .hilt: "GUARDA"
        case .grip: "MANGO"
        }
    }

    // MARK: - Círculo ritual

    private var ritualCircle: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = side / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                RuneCircle(active: recipe != nil)
                    .frame(width: side, height: side)
                    .position(center)

                OrbitingMinerals(minerals: minerals, radius: radius * 0.47)
                    .position(center)

                // Arma en el centro
                ZStack {
                    if chosenParts.isEmpty {
                        Text("?").font(Theme.font(34, weight: .black)).foregroundStyle(Color(hex: 0xC879F2).opacity(0.5))
                    } else {
                        PixelImage(image: WeaponArt.composite(partIDs: chosenParts.map(\.id)).makeCGImage(), scale: max(2, side / 110))
                            .shadow(color: Color(hex: 0xC879F2), radius: recipe != nil ? 12 : 4)
                    }
                }
                .position(center)

                ForEach(Array(PartSlot.allCases.enumerated()), id: \.element) { index, slot in
                    let angle = [-90.0, 150.0, 30.0][index] * .pi / 180
                    altar(slot)
                        .position(x: center.x + cos(angle) * radius * 0.78, y: center.y + sin(angle) * radius * 0.78)
                }
            }
        }
    }

    private func altar(_ slot: PartSlot) -> some View {
        let part = chosen[slot].flatMap(PartCatalog.part)
        return Button {
            activeSlot = slot
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 52, height: 52)
                        .overlay(Rectangle().strokeBorder(activeSlot == slot ? Theme.gold : Color(hex: 0xC879F2), style: StrokeStyle(lineWidth: 2, dash: part == nil ? [4, 3] : [])))
                    if let part {
                        PixelImage(image: Art.partImage(part), scale: 2)
                            .frame(width: 48, height: 48)
                    }
                }
                Text(shortName(slot))
                    .font(Theme.font(8, weight: .black))
                    .foregroundStyle(activeSlot == slot ? Theme.gold : Color(hex: 0xC879F2))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ofrenda

    private var offeringColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("MINERALES").font(Theme.font(10)).foregroundStyle(Theme.textDim)
                Spacer()
                Text("\(minerals.values.reduce(0, +))/\(WeaponRecipe.maxMinerals)").font(Theme.font(10)).foregroundStyle(Theme.text)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 5), spacing: 3) {
                ForEach(Mineral.allCases) { mineral in
                    mineralCell(mineral)
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    if let recipe {
                        Text(recipe.weaponName.uppercased())
                            .font(Theme.font(11, weight: .black))
                            .foregroundStyle(Theme.text)
                        StatLines(stats: recipe.stats(multiplier: 1), fontSize: 9)
                        abilityPreview(recipe)
                        Text("Suerte de la ruleta +\(Int(recipe.luck * 100))%")
                            .font(Theme.font(9))
                            .foregroundStyle(Theme.gold)
                        OddsBar(luck: recipe.luck)
                    } else {
                        Text("Coloca una hoja, una guarda y una empuñadura en los altares.")
                            .font(Theme.font(9, weight: .bold))
                            .foregroundStyle(Theme.textDim)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let errorMessage {
                Text(errorMessage).font(Theme.font(9, weight: .bold)).foregroundStyle(Theme.red)
            }
            Button {
                forge()
            } label: {
                HStack(spacing: 4) {
                    Text("✦ RITUAL")
                    PixelImage(image: Art.coin, scale: 1.5)
                    Text("\(recipe?.goldCost ?? 0)")
                }
            }
            .buttonStyle(.pixel(Color(hex: 0xC879F2), text: .black, size: 13))
            .disabled(recipe == nil)
        }
    }

    @ViewBuilder
    private func abilityPreview(_ recipe: WeaponRecipe) -> some View {
        let counts = recipe.parts.flatMap(\.elements).reduce(into: [Element: Int]()) { $0[$1, default: 0] += 1 }
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                ForEach(Element.allCases.filter { counts[$0] != nil }) { element in
                    Text("\(element.name) ×\(counts[element]!)")
                        .font(Theme.font(8, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 3)
                        .background(Color(hex: element.color))
                }
            }
            if let ability = recipe.ability {
                if store.profile.discoveredAbilities.contains(ability.id) {
                    Text("✦ \(ability.name)").font(Theme.font(11, weight: .black)).foregroundStyle(Color(hex: ability.elements.first?.color ?? 0xFFFFFF))
                    Text(ability.description).font(Theme.font(8, weight: .bold)).foregroundStyle(Theme.textDim).fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("✦ ??? Habilidad secreta").font(Theme.font(11, weight: .black)).foregroundStyle(Color(hex: 0xC879F2))
                }
            } else {
                Text("Sin habilidad: repite elementos para despertar una.")
                    .font(Theme.font(8, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func mineralCell(_ mineral: Mineral) -> some View {
        let owned = store.profile.count(of: mineral)
        let selected = minerals[mineral, default: 0]
        return Button {
            add(mineral)
        } label: {
            VStack(spacing: 0) {
                PixelImage(image: Art.mineralImage(mineral), scale: 2.2)
                Text("\(owned - selected)")
                    .font(Theme.font(8))
                    .foregroundStyle(owned - selected > 0 ? Theme.text : Theme.textDim.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .background(selected > 0 ? Theme.mineralColor(mineral).opacity(0.3) : Color.black.opacity(0.35))
            .overlay(Rectangle().strokeBorder(selected > 0 ? Theme.mineralColor(mineral) : Color.black, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if selected > 0 {
                Button { remove(mineral) } label: {
                    Text("\(selected)−")
                        .font(Theme.font(8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 2)
                        .background(Theme.red)
                }
                .buttonStyle(.plain)
                .offset(x: 3, y: -4)
            }
        }
    }

    private func add(_ mineral: Mineral) {
        guard minerals.values.reduce(0, +) < WeaponRecipe.maxMinerals,
              minerals[mineral, default: 0] < store.profile.count(of: mineral) else { return }
        minerals[mineral, default: 0] += 1
    }

    private func remove(_ mineral: Mineral) {
        guard let current = minerals[mineral], current > 0 else { return }
        minerals[mineral] = current > 1 ? current - 1 : nil
    }

    private func forge() {
        guard let recipe else { return }
        if let error = store.profile.validate(recipe) {
            errorMessage = error.message
            return
        }
        do {
            let luck = recipe.luck
            let result = try store.craft(recipe)
            chosen = [:]
            minerals = [:]
            activeSlot = .head
            pending = (result, luck)
        } catch let error as CraftError {
            errorMessage = error.message
        } catch {
            errorMessage = "El ritual ha fallado"
        }
    }

    /// Quita de la selección piezas que ya no se tienen.
    private func pruneSelection() {
        for (slot, id) in chosen where store.profile.partCount(id) == 0 { chosen[slot] = nil }
    }
}

/// Fila de una pieza: icono, nombre, cantidad y elementos.
struct PartRow: View {
    let part: WeaponPart
    let count: Int
    var selected = false

    var body: some View {
        HStack(spacing: 6) {
            PixelImage(image: Art.partImage(part), scale: 1.5)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(part.name)
                    .font(Theme.font(9, weight: .black))
                    .foregroundStyle(part.isSpecial ? Theme.gold : Theme.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    Text("×\(count)").font(Theme.font(8)).foregroundStyle(Theme.textDim)
                    ElementChips(elements: part.elements, fontSize: 7)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .background(selected ? Color(hex: 0x4A2A6A) : Theme.panel)
        .overlay(Rectangle().strokeBorder(selected ? Theme.gold : (part.isSpecial ? Theme.orange : Color.black), lineWidth: 2))
    }
}

/// Círculo de runas que gira despacio.
private struct RuneCircle: View {
    let active: Bool
    private static let runes = Array("ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛞᛟ")

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let r = min(size.width, size.height) / 2 - 4
                let glow = Color(hex: 0xC879F2).opacity(active ? 0.95 : 0.55)
                for (factor, width) in [(1.0, 3.0), (0.86, 1.5), (0.6, 2.0)] {
                    let rr = r * factor
                    context.stroke(Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2)),
                                   with: .color(glow), lineWidth: width)
                }
                // Triángulo entre los altares
                var triangle = Path()
                for (i, deg) in [-90.0, 150.0, 30.0, -90.0].enumerated() {
                    let a = deg * .pi / 180
                    let p = CGPoint(x: center.x + cos(a) * r * 0.78, y: center.y + sin(a) * r * 0.78)
                    if i == 0 { triangle.move(to: p) } else { triangle.addLine(to: p) }
                }
                context.stroke(triangle, with: .color(glow.opacity(0.6)), lineWidth: 1.5)
                // Runas girando entre los dos anillos exteriores
                let count = Self.runes.count
                let spin = t * (active ? 0.5 : 0.15)
                for i in 0..<count {
                    let a = Double(i) / Double(count) * 2 * .pi + spin
                    let p = CGPoint(x: center.x + cos(a) * r * 0.93, y: center.y + sin(a) * r * 0.93)
                    context.draw(Text(String(Self.runes[i])).font(.system(size: max(8, r * 0.08), weight: .bold)).foregroundStyle(glow), at: p)
                }
            }
        }
    }
}

/// Minerales ofrecidos girando alrededor del arma.
private struct OrbitingMinerals: View {
    let minerals: [Mineral: Int]
    let radius: CGFloat

    var body: some View {
        let list = Mineral.allCases.flatMap { Array(repeating: $0, count: minerals[$0, default: 0]) }
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(Array(list.enumerated()), id: \.offset) { index, mineral in
                    let a = Double(index) / Double(max(1, list.count)) * 2 * .pi - t * 0.8
                    PixelImage(image: Art.mineralImage(mineral), scale: 2)
                        .offset(x: cos(a) * radius, y: sin(a) * radius)
                }
            }
        }
    }
}

/// Barra con la probabilidad de cada casilla de la ruleta.
struct OddsBar: View {
    let luck: Double

    var body: some View {
        let probs = Roulette.probabilities(luck: luck)
        VStack(alignment: .leading, spacing: 2) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(probs.enumerated()), id: \.offset) { index, p in
                        Rectangle().fill(RitualRevealView.color(for: index)).frame(width: geo.size.width * p)
                    }
                }
            }
            .frame(height: 8)
            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 1))
            Text("Obra maestra: \(Int((probs.last! * 100).rounded()))% · Rota: \(Int((probs.first! * 100).rounded()))%")
                .font(Theme.font(8, weight: .bold))
                .foregroundStyle(Theme.textDim)
        }
    }
}
