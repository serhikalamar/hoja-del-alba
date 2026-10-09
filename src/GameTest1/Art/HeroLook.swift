import CoreGraphics
import GameCore

// CONTRATO ENTRE EL JUEGO Y EL ARTE DEL HÉROE
// El juego describe cómo se ve el héroe con `HeroLook`; `HeroArt` (HeroArt.swift) lo dibuja.
// No cambies estas firmas sin actualizar a la vez quien las usa (HeroNode, vistas).

/// Una pieza de armadura tal y como se ve puesta.
struct GearLook: Hashable {
    /// Diseño (`ArmorCatalog.styles`): "helm.knight", "chest.plate", "gloves.wraps", "boots.fur"…
    var styleID: String
    /// Colores del material (claro, medio, oscuro).
    var material: [UInt32]
    /// Tinte elegido por el jugador: tela, penachos, ribetes.
    var dye: UInt32

    /// Aspecto de un objeto equipado (incluye la armadura antigua de un solo hueco).
    static func from(_ item: Item) -> GearLook? {
        if let style = item.styleID {
            let material = ArmorCatalog.material(item.materialID)?.palette ?? PartMaterial.metals[1].palette
            return GearLook(styleID: style, material: material, dye: UInt32(item.dye ?? 0x3B5DC9))
        }
        guard item.slot == .chest else { return nil }
        // Armaduras antiguas (v0.1-v0.3): se traducen a un diseño nuevo.
        switch item.icon {
        case "armor_leather": return GearLook(styleID: "chest.leather", material: PartMaterial.leathers[0].palette, dye: 0x7A4A2A)
        case "armor_chain": return GearLook(styleID: "chest.chain", material: PartMaterial.metals[1].palette, dye: 0x3B5DC9)
        case "armor_scale": return GearLook(styleID: "chest.chain", material: PartMaterial.metals[4].palette, dye: 0x2E8A44)
        case "armor_plate": return GearLook(styleID: "chest.plate", material: PartMaterial.metals[2].palette, dye: 0xB13E53)
        case "armor_elven": return GearLook(styleID: "chest.robe", material: PartMaterial.cloths[2].palette, dye: 0x2A9AA0)
        default: return GearLook(styleID: "chest.tabard", material: PartMaterial.cloths[0].palette, dye: 0x9A6A44)
        }
    }
}

/// Todo lo que hace falta para dibujar al héroe.
struct HeroLook: Hashable {
    var race: Race
    var appearance: Appearance
    /// Armadura por hueco (`.helmet`, `.chest`, `.gloves`, `.boots`). Un hueco vacío = sin pieza.
    var gear: [EquipmentSlot: GearLook]
    /// Detalles solo de NPC (barba, capa, casco bajo el brazo…; ver HeroExtras.swift). Vacío en el héroe.
    var extras: LookExtras

    init(race: Race, appearance: Appearance = Appearance(), gear: [EquipmentSlot: GearLook] = [:], extras: LookExtras = LookExtras()) {
        self.race = race
        self.appearance = appearance
        self.gear = gear
        self.extras = extras
    }

    init(profile: PlayerProfile) {
        var gear: [EquipmentSlot: GearLook] = [:]
        for slot in EquipmentSlot.gear {
            if let item = profile.equipped(slot), let look = GearLook.from(item) { gear[slot] = look }
        }
        self.init(race: profile.race, appearance: profile.appearance ?? Appearance(), gear: gear)
    }

    /// Aspecto de un personaje recién creado (túnica de lino inicial).
    static func starter(race: Race, appearance: Appearance) -> HeroLook {
        HeroLook(race: race, appearance: appearance,
                 gear: [.chest: GearLook(styleID: "chest.tabard", material: PartMaterial.cloths[0].palette, dye: 0x9A6A44)])
    }

    /// Clave estable para la caché de texturas.
    var cacheKey: String {
        let a = appearance
        let parts = EquipmentSlot.gear.map { slot -> String in
            guard let g = gear[slot] else { return "-" }
            return "\(g.styleID):\(g.material.map { String($0, radix: 16) }.joined(separator: ",")):\(String(g.dye, radix: 16))"
        }
        let base = "\(race.rawValue).\(a.skinTone).\(a.hairStyle).\(a.hairColor).\(a.eyeColor).\(parts.joined(separator: "|"))"
        return extras.isEmpty ? base : base + "|x:" + extras.cacheKey
    }
}

/// Opciones de personalización que ofrece cada raza en la pantalla de creación.
struct AppearanceOptions {
    var skinTones: [UInt32]
    /// Nombres de los peinados (o barbas, crines…), en el orden de `Appearance.hairStyle`.
    var hairStyles: [String]
    var hairColors: [UInt32]
    var eyeColors: [UInt32]
    /// Etiquetas en la interfaz ("Peinado", "Barba", "Melena"…).
    var skinLabel = "Piel"
    var hairStyleLabel = "Peinado"
    var hairColorLabel = "Color de pelo"
    var eyeLabel = "Ojos"
}
