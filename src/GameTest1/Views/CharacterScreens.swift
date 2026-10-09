import GameCore
import SwiftUI

// Pantallas de inicio al estilo de un MMORPG: selección y creación de personaje.

// MARK: - Fondo común

/// Muralla del castillo de noche, antorchas y un pedestal de piedra para el personaje.
private let stageBackdrop = VillageArt.background(width: 300, height: 140, level: Worlds.village.level(9)!)

struct CharacterStage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Image(decorative: stageBackdrop, scale: 1)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(colors: [Color.black.opacity(0.25), Color.black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
            // Luz de las antorchas
            TimelineView(.animation(minimumInterval: 0.12)) { timeline in
                let flicker = 0.85 + 0.15 * sin(timeline.date.timeIntervalSinceReferenceDate * 9)
                GeometryReader { geo in
                    ForEach([0.22, 0.78], id: \.self) { x in
                        Torch(flicker: flicker)
                            .position(x: geo.size.width * x, y: geo.size.height * 0.38)
                    }
                }
            }
            .ignoresSafeArea()
            content
        }
    }
}

private struct Torch: View {
    let flicker: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFFB040).opacity(0.45 * flicker), .clear], center: .center, startRadius: 2, endRadius: 90))
                .frame(width: 180, height: 180)
            VStack(spacing: 0) {
                Ellipse().fill(Color(hex: 0xFFE070)).frame(width: 10 * flicker, height: 16 * flicker)
                    .overlay(Ellipse().fill(Color(hex: 0xFF7A20)).frame(width: 6, height: 9).offset(y: 3))
                Rectangle().fill(Color(hex: 0x4A3020)).frame(width: 6, height: 22)
                    .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 1.5))
            }
        }
    }
}

/// Pedestal de piedra bajo el personaje.
private struct Pedestal: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.5)).frame(width: 190, height: 44).offset(y: 6)
            Ellipse().fill(Color(hex: 0x6A6A78)).frame(width: 180, height: 40)
            Ellipse().fill(Color(hex: 0x8A8A96)).frame(width: 164, height: 30).offset(y: -3)
            Ellipse().stroke(Color(hex: 0xC879F2).opacity(0.6), lineWidth: 2).frame(width: 140, height: 22).offset(y: -3)
        }
    }
}

// MARK: - Vista previa animada del héroe

struct HeroPreview: View {
    enum Animation: String, CaseIterable {
        case idle = "Quieto", run = "Correr", attack = "Atacar"
    }

    let look: HeroLook
    var weapon: Item?
    var animation: Animation = .idle
    var facingLeft = false
    var scale: CGFloat = 4

    private var poses: [HeroArt.Pose] {
        switch animation {
        case .idle: [.idle0, .idle0, .idle0, .idle0, .idle1, .idle1, .idle1, .idle1, .idle0, .idle0, .idle0, .idle1, .idle1, .idle2]
        case .run: HeroArt.runPoses
        case .attack: [.idle0, .idle0, .windup, .windup, .strike, .strike, .strike, .recover, .recover, .idle0, .idle0, .idle0]
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: animation == .idle ? 0.13 : 0.09)) { timeline in
            let index = Int(timeline.date.timeIntervalSinceReferenceDate / (animation == .idle ? 0.13 : 0.09)) % poses.count
            let pose = poses[index]
            let image = Art.heroImage(look, pose: pose)
            ZStack(alignment: .topLeading) {
                PixelImage(image: image, scale: scale)
                if let weapon {
                    weaponView(weapon, pose: pose)
                }
            }
            .frame(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale, alignment: .topLeading)
            .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
        }
    }

    /// El arma en la mano, como en el juego.
    private func weaponView(_ item: Item, pose: HeroArt.Pose) -> some View {
        let image = Art.itemImage(item)
        let forged = item.partIDs != nil
        let weaponScale = forged ? scale : scale * 1.4
        let grip = forged
            ? CGPoint(x: CGFloat(image.width) / 2, y: WeaponArt.gripPoint.y + 1)
            : CGPoint(x: 5.5, y: 10.5)
        let hand = HeroArt.hand(look, pose: pose)
        let angle: Double = switch pose {
        case .windup: 63
        case .strike: -126
        default: -17
        }
        return PixelImage(image: image, scale: weaponScale)
            .rotationEffect(.degrees(-angle), anchor: UnitPoint(x: grip.x / CGFloat(image.width), y: grip.y / CGFloat(image.height)))
            .offset(x: hand.x * scale - grip.x * weaponScale, y: hand.y * scale - grip.y * weaponScale)
    }
}

// MARK: - Selección de personaje

struct CharacterSelectView: View {
    @Environment(GameStore.self) private var store
    @State private var facingLeft = false
    @State private var confirmDelete = false
    @State private var showAccount = false

    var body: some View {
        CharacterStage {
            HStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("REINO DE VALDEHIERRO")
                        .font(Theme.font(12, weight: .black))
                        .foregroundStyle(Theme.textDim)
                    Text((store.profile.name ?? "Héroe").uppercased())
                        .font(Theme.font(30, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                    Text("Nivel \(store.profile.characterLevel) · \(store.profile.race.name) · Aldeanos \(store.profile.town.rescued.count)/\(Valdehierro.villagerIDs.count) · Arena: oleada \(store.profile.arenaBestWave ?? 0)")
                        .font(Theme.font(11, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                    Spacer(minLength: 0)
                    ZStack(alignment: .bottom) {
                        Pedestal().offset(y: 14)
                        HeroPreview(look: HeroLook(profile: store.profile), weapon: store.profile.equippedWeapon,
                                    facingLeft: facingLeft, scale: 3.6)
                    }
                    HStack(spacing: 12) {
                        Button("◀") { facingLeft = true }
                            .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 50))
                        Button { store.startTown() } label: {
                            VStack(spacing: 1) {
                                Text("▶ JUGAR")
                                Text("Historia").font(Theme.font(10, weight: .bold))
                            }
                            .frame(minWidth: 150)
                        }
                        .buttonStyle(.pixel(Color(hex: 0x2E8A44), text: .white, size: 19, minHeight: 50))
                        Button { store.startArena() } label: {
                            VStack(spacing: 1) {
                                Text("⚔ ARENA")
                                Text("Récord: oleada \(store.profile.arenaBestWave ?? 0)").font(Theme.font(10, weight: .bold))
                            }
                            .frame(minWidth: 150)
                        }
                        .buttonStyle(.pixel(Color(hex: 0xB01A1A), text: Theme.gold, size: 19, minHeight: 50))
                        Button("▶") { facingLeft = false }
                            .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 50))
                    }
                    .disabled(store.roster.characters.isEmpty)
                    .padding(.top, 14)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)

                characterList
                    .frame(width: 230)
                    .padding(.trailing, 14)
                    .padding(.vertical, 14)
            }
        }
        .confirmationDialog("¿Borrar a \(store.profile.name ?? "este personaje")? Se pierde todo su progreso.",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Borrar personaje", role: .destructive) {
                if let id = store.profile.characterID { store.deleteCharacter(id) }
            }
        }
        .accountPanel(isPresented: $showAccount)
    }

    private var characterList: some View {
        VStack(alignment: .leading, spacing: 6) {
            AccountButton { showAccount = true }
            Text("PERSONAJES").font(Theme.font(13, weight: .black)).foregroundStyle(Theme.gold)
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(store.roster.characters, id: \.characterID) { character in
                        let selected = character.characterID == store.profile.characterID
                        Button {
                            if let id = character.characterID { store.select(id) }
                        } label: {
                            HStack(spacing: 8) {
                                PixelImage(image: Art.heroImage(HeroLook(profile: character)), scale: 1.1)
                                    .frame(width: 40, height: 46)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(character.name ?? "Héroe")
                                        .font(Theme.font(13, weight: .black))
                                        .foregroundStyle(selected ? Theme.gold : Theme.text)
                                    Text("Nv \(character.characterLevel) · \(character.race.name)")
                                        .font(Theme.font(10, weight: .bold))
                                        .foregroundStyle(Theme.textDim)
                                    Text("Valdehierro")
                                        .font(Theme.font(9, weight: .bold))
                                        .foregroundStyle(Theme.textDim.opacity(0.7))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(6)
                            .background(selected ? Color(hex: 0x3A2A10).opacity(0.9) : Color.black.opacity(0.55))
                            .overlay(Rectangle().strokeBorder(selected ? Theme.gold : Theme.border.opacity(0.5), lineWidth: selected ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .clipped()  // el fondo de la fila elegida no debe salirse del panel
            Button("+ CREAR PERSONAJE") { store.go(to: .characterCreate) }
                .buttonStyle(.pixel(Theme.green, text: .black, size: 12))
                .disabled(store.roster.characters.count >= Roster.maxCharacters)
            Button("Borrar personaje") { confirmDelete = true }
                .buttonStyle(.pixel(Theme.panel, text: Theme.red, size: 10))
                .disabled(store.roster.characters.isEmpty)
        }
        .padding(10)
        .background(Color.black.opacity(0.55))
        .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.6), lineWidth: 2))
    }
}

// MARK: - Creación de personaje

struct CharacterCreateView: View {
    @Environment(GameStore.self) private var store
    @State private var race: Race = .human
    @State private var appearance = Appearance()
    @State private var name = ""
    @State private var animation: HeroPreview.Animation = .idle
    @State private var facingLeft = false
    @State private var errorMessage: String?
    @State private var showAccount = false

    private var options: AppearanceOptions { HeroArt.options(for: race) }

    var body: some View {
        CharacterStage {
            HStack(alignment: .top, spacing: 12) {
                racePanel.frame(width: 200)
                VStack(spacing: 8) {
                    Text("CREAR PERSONAJE")
                        .font(Theme.font(22, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                    Spacer(minLength: 0)
                    ZStack(alignment: .bottom) {
                        Pedestal().offset(y: 14)
                        HeroPreview(look: HeroLook.starter(race: race, appearance: appearance), animation: animation,
                                    facingLeft: facingLeft, scale: 3.4)
                    }
                    HStack(spacing: 6) {
                        Button("◀") { facingLeft = true }.buttonStyle(.pixel(Theme.panelLight, size: 11))
                        ForEach(HeroPreview.Animation.allCases, id: \.self) { anim in
                            Button(anim.rawValue) { animation = anim }
                                .buttonStyle(.pixel(animation == anim ? Theme.gold : Theme.panelLight,
                                                    text: animation == anim ? .black : Theme.text, size: 10))
                        }
                        Button("▶") { facingLeft = false }.buttonStyle(.pixel(Theme.panelLight, size: 11))
                    }
                    .padding(.top, 10)
                    nameBar
                }
                .frame(maxWidth: .infinity)
                customizationPanel.frame(width: 210)
            }
            .padding(14)
        }
        .onAppear { name = Self.randomName(for: race) }
        .accountPanel(isPresented: $showAccount)
    }

    // MARK: Razas

    private var racePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RAZA").font(Theme.font(13, weight: .black)).foregroundStyle(Theme.gold)
            ForEach(Race.allCases) { r in
                Button {
                    race = r
                    appearance = Appearance()
                    if name.isEmpty || Self.allNames.contains(name) { name = Self.randomName(for: r) }
                } label: {
                    HStack(spacing: 8) {
                        PixelImage(image: Art.heroImage(HeroLook.starter(race: r, appearance: Appearance())), scale: 0.9)
                            .frame(width: 34, height: 38)
                        Text(r.name.uppercased())
                            .font(Theme.font(12, weight: .black))
                            .foregroundStyle(r == race ? Theme.gold : Theme.text)
                        Spacer(minLength: 0)
                    }
                    .padding(4)
                    .background(r == race ? Color(hex: 0x3A2A10).opacity(0.9) : Color.black.opacity(0.5))
                    .overlay(Rectangle().strokeBorder(r == race ? Theme.gold : Theme.border.opacity(0.4), lineWidth: r == race ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
            Text(race.summary)
                .font(Theme.font(9, weight: .bold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            let s = race.baseStats
            VStack(alignment: .leading, spacing: 1) {
                ForEach([StatKind.maxHP, .attack, .defense, .attackSpeed, .moveSpeed], id: \.self) { kind in
                    HStack {
                        Text(kind.shortName).foregroundStyle(Theme.textDim)
                        Spacer()
                        Text(kind.formatValue(s[kind])).foregroundStyle(Theme.text)
                    }
                    .font(Theme.font(9, weight: .bold))
                }
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.55))
        .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.6), lineWidth: 2))
    }

    // MARK: Personalización

    private var customizationPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APARIENCIA").font(Theme.font(13, weight: .black)).foregroundStyle(Theme.gold)
            stepper(options.hairStyleLabel, value: $appearance.hairStyle, names: options.hairStyles)
            swatches(options.hairColorLabel, colors: options.hairColors, selection: $appearance.hairColor)
            swatches(options.skinLabel, colors: options.skinTones, selection: $appearance.skinTone)
            swatches(options.eyeLabel, colors: options.eyeColors, selection: $appearance.eyeColor)
            Spacer(minLength: 0)
            Button("🎲 ALEATORIO") {
                appearance = Appearance(skinTone: Int.random(in: 0..<max(1, options.skinTones.count)),
                                        hairStyle: Int.random(in: 0..<max(1, options.hairStyles.count)),
                                        hairColor: Int.random(in: 0..<max(1, options.hairColors.count)),
                                        eyeColor: Int.random(in: 0..<max(1, options.eyeColors.count)))
            }
            .buttonStyle(.pixel(Theme.panelLight, size: 11))
        }
        .padding(10)
        .background(Color.black.opacity(0.55))
        .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.6), lineWidth: 2))
    }

    private func stepper(_ label: String, value: Binding<Int>, names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(Theme.font(9, weight: .black)).foregroundStyle(Theme.textDim)
            HStack(spacing: 4) {
                Button("◀") { value.wrappedValue = (value.wrappedValue - 1 + names.count) % max(1, names.count) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 10))
                Text(names.isEmpty ? "—" : names[min(value.wrappedValue, names.count - 1)])
                    .font(Theme.font(11, weight: .black))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Button("▶") { value.wrappedValue = (value.wrappedValue + 1) % max(1, names.count) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 10))
            }
        }
    }

    private func swatches(_ label: String, colors: [UInt32], selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(Theme.font(9, weight: .black)).foregroundStyle(Theme.textDim)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 4), count: 8), alignment: .leading, spacing: 4) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    Rectangle()
                        .fill(Color(hex: color))
                        .frame(width: 20, height: 20)
                        .overlay(Rectangle().strokeBorder(index == selection.wrappedValue ? Theme.gold : Color.black,
                                                          lineWidth: index == selection.wrappedValue ? 3 : 1))
                        .onTapGesture { selection.wrappedValue = index }
                }
            }
        }
    }

    // MARK: Nombre

    private var nameBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                TextField("Nombre", text: $name)
                    .textFieldStyle(.plain)
                    .font(Theme.font(16, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(width: 220)
                    .background(Color.black.opacity(0.7))
                    .overlay(Rectangle().strokeBorder(Theme.gold, lineWidth: 2))
                    .onChange(of: name) { _, _ in errorMessage = nil }
                Button("🎲") { name = Self.randomName(for: race) }
                    .buttonStyle(.pixel(Theme.panelLight, size: 13))
            }
            if let errorMessage {
                Text(errorMessage).font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.red)
            }
            HStack(spacing: 10) {
                if !store.roster.characters.isEmpty {
                    Button("VOLVER") { store.go(to: .characterSelect) }
                        .buttonStyle(.pixel(Theme.panelLight, size: 13))
                }
                // Para recuperar los personajes de una cuenta en un dispositivo nuevo.
                AccountButton(compact: true) { showAccount = true }
                Button("CREAR PERSONAJE") { create() }
                    .buttonStyle(.pixel(Color(hex: 0xB01A1A), text: Theme.gold, size: 16))
            }
        }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard PlayerProfile.isValidName(trimmed) else {
            errorMessage = "El nombre debe tener entre 2 y 14 letras."
            return
        }
        guard !store.roster.isNameTaken(trimmed) else {
            errorMessage = "Ya tienes un personaje llamado \(trimmed)."
            return
        }
        if !store.createCharacter(name: trimmed, race: race, appearance: appearance) {
            errorMessage = "No se ha podido crear el personaje."
        }
    }

    // MARK: Nombres aleatorios

    private static let names: [Race: [String]] = [
        .human: ["Aldric", "Rowena", "Tristán", "Elvira", "Gonzalo", "Isolda", "Rodrigo", "Ximena"],
        .dwarf: ["Thorgrim", "Brunhilda", "Durin", "Helga", "Balin", "Gudrun", "Korgan", "Dagna"],
        .elf: ["Aelar", "Lúthien", "Thalion", "Elaria", "Faelyn", "Sylvar", "Nimriel", "Caladwen"],
        .werewolf: ["Fenrir", "Ulfric", "Garra Gris", "Luna", "Vargr", "Colmillo", "Skoll", "Nieve"],
    ]

    private static var allNames: Set<String> { Set(names.values.flatMap { $0 }) }

    static func randomName(for race: Race) -> String {
        names[race]?.randomElement() ?? "Héroe"
    }
}
