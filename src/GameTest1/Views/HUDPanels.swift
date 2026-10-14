import GameCore
import SwiftUI

// Piezas del HUD mientras se juega: retrato del héroe (abre su ficha) y botón "!" de la misión seguida (abre su panel).
// La ficha sirve también en la arena (`BattleView`).

// MARK: - Retrato del héroe

/// Busto del héroe con su equipo, enmarcado. Al tocarlo se abre la ficha del personaje.
struct HeroPortraitButton: View {
    let look: HeroLook
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PixelImage(image: Art.heroBust(look), scale: 1.5)
                .frame(width: 46, height: 46)
                .background(Theme.panel.opacity(0.9))
                .overlay(Rectangle().inset(by: 2).strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
                .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
                .clipped()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ficha del personaje")
    }
}

// MARK: - Botones de icono del HUD (mapa, inventario)

/// Botón cuadrado de 44 pt con un icono pixel-art, del mismo estilo que el "!" de la misión.
struct HUDIconButton: View {
    let key: String
    let icon: () -> PixelGrid
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PixelImage(image: Art.gridImage(key, icon()), scale: 2)
                .frame(width: 44, height: 44)
                .background(Theme.panel.opacity(0.9))
                .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Botón "!" de la misión

/// "!" dorado (el mismo dibujo que sobre los NPC). Punto rojo si hay misiones nuevas o para entregar; rebota si
/// alguna aún no se ha visto en el panel.
struct QuestButton: View {
    let alerts: Int
    let isNew: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PixelImage(image: Art.gridImage("questMarker.offer", Sprites.questMarker(.offer)), scale: 2)
                .phaseAnimator(isNew ? [0.0, -5.0, 0.0, 0.0] : [0.0]) { view, offset in
                    view.offset(y: offset)
                } animation: { _ in .easeInOut(duration: 0.22) }
                .frame(width: 44, height: 44)
                .background(Theme.panel.opacity(0.9))
                .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
                .overlay(alignment: .topTrailing) {
                    if alerts > 0 {
                        Text("\(alerts)")
                            .font(Theme.font(9, weight: .black))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Theme.red)
                            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 2))
                            .offset(x: 6, y: -6)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Misión")
    }
}

// MARK: - Ficha del personaje

/// Ficha del personaje: nombre, raza, nivel y XP, estadísticas totales, equipo puesto, oro y minerales.
/// Sin vender ni forjar; "CAMBIAR EQUIPO" abre el inventario de la pausa.
struct CharacterSheetView: View {
    @Environment(GameStore.self) private var store
    let onClose: () -> Void
    @State private var showingInventory = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button(showingInventory ? "◀ FICHA" : "◀ VOLVER") {
                        if showingInventory { showingInventory = false } else { onClose() }
                    }
                    .buttonStyle(.pixel(Theme.panelLight, size: 13, minHeight: 44))
                    Text(showingInventory ? "INVENTARIO" : "FICHA DEL PERSONAJE")
                        .font(Theme.font(18, weight: .black)).foregroundStyle(Theme.gold)
                    Spacer()
                    if !showingInventory {
                        Button("▤ CAMBIAR EQUIPO") { showingInventory = true }
                            .buttonStyle(.pixel(Theme.blue, text: .black, size: 12, minHeight: 44))
                    }
                }
                if showingInventory {
                    InventoryView(allowsTrading: false)
                } else {
                    sheet
                }
            }
            .padding(14)
            .frame(maxWidth: 760)
            .pixelPanel(fill: Theme.background.opacity(0.97))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var sheet: some View {
        let profile = store.profile
        return HStack(alignment: .top, spacing: 12) {
            identity(profile).frame(width: 180)
            stats(profile.totalStats).frame(width: 170)
            gear(profile).frame(maxWidth: .infinity)
        }
    }

    private func identity(_ profile: PlayerProfile) -> some View {
        let need = Leveling.xpToNext(profile.characterLevel)
        let progress = need > 0 ? Double(profile.levelXP) / Double(need) : 1
        return VStack(spacing: 5) {
            HeroPreview(look: HeroLook(profile: profile), weapon: profile.equippedWeapon, scale: 2.4)
                .frame(height: 124)
            Text((profile.name ?? "Héroe").uppercased())
                .font(Theme.font(15, weight: .black)).foregroundStyle(Theme.gold)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(profile.race.name.uppercased())
                .font(Theme.font(10, weight: .black)).foregroundStyle(Theme.textDim)
            LevelBadge(level: profile.characterLevel, progress: progress, width: 170)
            Text(need > 0 ? "XP \(profile.levelXP)/\(need)" : "NIVEL MÁXIMO")
                .font(Theme.font(9, weight: .bold)).foregroundStyle(Theme.textDim)
        }
        .padding(8)
        .pixelPanel()
    }

    private func stats(_ stats: Stats) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("ESTADÍSTICAS").font(Theme.font(11, weight: .black)).foregroundStyle(Theme.orange)
            ForEach(StatKind.allCases, id: \.self) { kind in
                HStack {
                    Text(kind.shortName).font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.textDim)
                    Spacer()
                    Text(kind.formatValue(stats[kind])).font(Theme.font(10)).foregroundStyle(Theme.text)
                }
            }
        }
        .padding(8)
        .pixelPanel()
    }

    private func gear(_ profile: PlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("EQUIPO").font(Theme.font(11, weight: .black)).foregroundStyle(Theme.orange)
            weaponRow(profile.equippedWeapon)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                ForEach(EquipmentSlot.gear) { slot in gearCell(slot, item: profile.equipped(slot)) }
            }
            HStack(spacing: 10) {
                GoldLabel(amount: profile.gold, size: 14)
                Spacer()
            }
            .padding(.top, 2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), alignment: .leading, spacing: 4) {
                ForEach(Mineral.allCases) { mineral in
                    MineralChip(mineral: mineral, count: profile.count(of: mineral), scale: 2)
                }
            }
        }
        .padding(8)
        .pixelPanel()
    }

    private func weaponRow(_ weapon: Item?) -> some View {
        HStack(spacing: 8) {
            itemIcon(weapon, size: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(weapon?.name ?? "Sin arma")
                    .font(Theme.font(11, weight: .black))
                    .foregroundStyle(weapon.map { Theme.rarityColor($0.rarity) } ?? Theme.textDim)
                    .lineLimit(1)
                AbilityTag(ability: weapon?.ability, fontSize: 10)
                if let ability = weapon?.ability, store.profile.discoveredAbilities.contains(ability.id) {
                    Text(ability.description)
                        .font(Theme.font(8, weight: .bold)).foregroundStyle(Theme.textDim)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func gearCell(_ slot: EquipmentSlot, item: Item?) -> some View {
        HStack(spacing: 5) {
            itemIcon(item, size: 28)
            VStack(alignment: .leading, spacing: 0) {
                Text(slot.name.uppercased()).font(Theme.font(7, weight: .black)).foregroundStyle(Theme.textDim)
                Text(item?.name ?? "—")
                    .font(Theme.font(9, weight: .black))
                    .foregroundStyle(item.map { Theme.rarityColor($0.rarity) } ?? Theme.textDim.opacity(0.6))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
    }

    private func itemIcon(_ item: Item?, size: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(0.45))
            if let item {
                PixelImage(image: Art.itemImage(item), scale: item.partIDs != nil ? size / 34 : size / 17)
            }
        }
        .frame(width: size, height: size)
        .overlay(Rectangle().strokeBorder(item.map { Theme.rarityColor($0.rarity) } ?? Theme.border.opacity(0.4), lineWidth: 2))
        .clipped()
    }
}

// MARK: - Panel de la misión

/// Misión seguida (título, quién la da, objetivos, recompensa y dónde ir), las activas para cambiar cuál se sigue,
/// los avisos (nuevas y para entregar) y el acceso al diario completo.
struct QuestPanelView: View {
    @Environment(GameStore.self) private var store
    let session: ExploreSession
    @State private var showingJournal = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { session.closePanel() }
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button("◀ VOLVER") { session.closePanel() }
                        .buttonStyle(.pixel(Theme.green, text: .black, size: 13, minHeight: 44))
                    Text(showingJournal ? "DIARIO" : "MISIÓN").font(Theme.font(18, weight: .black)).foregroundStyle(Theme.gold)
                    Spacer()
                    Button(showingJournal ? "! MISIÓN" : "✎ DIARIO") { showingJournal.toggle() }
                        .buttonStyle(.pixel(Theme.panelLight, size: 12, minHeight: 44))
                }
                if showingJournal {
                    QuestJournalView(session: session)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        tracked.frame(maxWidth: .infinity, alignment: .topLeading)
                        sideList.frame(width: 250)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: 720, maxHeight: 340)
            .pixelPanel(fill: Theme.background.opacity(0.97))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: Misión seguida

    @ViewBuilder
    private var tracked: some View {
        ScrollView {
            if let quest = session.trackedQuest {
                VStack(alignment: .leading, spacing: 5) {
                    Text("SIGUIENDO").font(Theme.font(9, weight: .black)).foregroundStyle(Theme.orange)
                    Text(quest.title).font(Theme.font(16, weight: .black)).foregroundStyle(Theme.gold)
                    Text("La da: \(giverName(quest))").font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.textDim)
                    Text(quest.summary)
                        .font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(session.journal(quest).enumerated()), id: \.offset) { _, line in
                            Text((line.isDone ? "✔ " : "· ") + line.text + (line.counter.isEmpty ? "" : " \(line.counter)"))
                                .font(Theme.font(11, weight: .black))
                                .foregroundStyle(line.isDone ? Theme.green : Theme.text)
                        }
                        if store.profile.isComplete(quest), !quest.completesOnLastObjective {
                            Text("? Vuelve con \(giverName(quest)) para entregarla")
                                .font(Theme.font(11, weight: .black)).foregroundStyle(Theme.gold)
                        }
                    }
                    .padding(.vertical, 3)
                    infoRow("RECOMPENSA", PlayerProfile.rewardText(quest.reward))
                    if let place = session.destination(of: quest) {
                        infoRow("DÓNDE IR", place.name + (place.areaID == session.areaID ? " (estás aquí)" : ""))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("SIN MISIÓN EN CURSO").font(Theme.font(12, weight: .black)).foregroundStyle(Theme.orange)
                    Text(session.objective).font(Theme.font(11, weight: .bold)).foregroundStyle(Theme.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(Theme.font(8, weight: .black)).foregroundStyle(Theme.orange)
            Text(value).font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Activas y avisos

    private var sideList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("EN CURSO · toca para seguir").font(Theme.font(9, weight: .black)).foregroundStyle(Theme.orange)
                ForEach(session.activeQuests, id: \.id) { quest in
                    let isTracked = session.trackedQuest?.id == quest.id
                    Button { session.track(quest.id) } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text((isTracked ? "▶ " : "") + quest.title)
                                .font(Theme.font(11, weight: .black))
                                .foregroundStyle(isTracked ? Color.black : Theme.text)
                                .lineLimit(1)
                            Text(store.profile.trackerText(quest))
                                .font(Theme.font(8, weight: .bold))
                                .foregroundStyle(isTracked ? Color.black.opacity(0.75) : Theme.textDim)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isTracked ? Theme.gold : Theme.panel)
                        .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 2))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                let alerts = session.questAlerts
                if !alerts.isEmpty {
                    Text("AVISOS").font(Theme.font(9, weight: .black)).foregroundStyle(Theme.orange).padding(.top, 4)
                    ForEach(alerts, id: \.self) { alert in
                        HStack(alignment: .top, spacing: 6) {
                            PixelImage(image: Art.gridImage(alert.kind == .newQuest ? "questMarker.offer" : "questMarker.turnIn",
                                                            Sprites.questMarker(alert.kind == .newQuest ? .offer : .turnIn)), scale: 1)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(alertText(alert)).font(Theme.font(9, weight: .black)).foregroundStyle(Theme.text)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let place = store.profile.place(ofNPC: alert.npcID) {
                                    Text(place.name).font(Theme.font(8, weight: .bold)).foregroundStyle(Theme.textDim)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
    }

    private func giverName(_ quest: Quest) -> String {
        if quest.giverID == ValdemarQuests.smithID { return ValdemarDialogue.smithName }
        return World.npc(quest.giverID)?.name ?? World.npcShortName(quest.giverID)
    }

    private func alertText(_ alert: QuestAlert) -> String {
        let who = World.npcShortName(alert.npcID)
        let name = who.prefix(1).uppercased() + who.dropFirst()
        switch alert.kind {
        case .newQuest: return "\(name) tiene una misión nueva"
        case .turnIn: return "Habla con \(who): \(World.quest(alert.questID)?.title ?? "")"
        }
    }
}
