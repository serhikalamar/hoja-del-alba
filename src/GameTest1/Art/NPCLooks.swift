import CoreGraphics
import GameCore
import SpriteKit

/// Aldeanos y princesa dibujados con el mismo sistema que el héroe (`HeroArt`): misma escala, mismo tamaño
/// de pixel y estilo chibi. Cada oficio se reconoce por su raza, peinado y ropa.
enum NPCLooks {
    /// Aspecto de un aldeano (`NPC.look`), o nil si no tiene versión chibi.
    static func look(_ id: String) -> HeroLook? {
        switch id {
        case "baker":
            return dressed(.human, hair: 2, hairColor: 0x8A5A30, skin: 0xF0BE98, eyes: 0x38B764,
                           chest: ("chest.robe", PartMaterial.cloths[0].palette, 0xF4F4F4),
                           boots: ("boots.leather", PartMaterial.leathers[0].palette, 0x7A4A2A))
        case "weaver":
            return dressed(.elf, hair: 1, hairColor: 0xD86A3A, skin: 0xF2CCAE, eyes: 0x2FB6B8,
                           chest: ("chest.robe", PartMaterial.cloths[1].palette, 0x5D275D),
                           gloves: ("gloves.wraps", PartMaterial.cloths[1].palette, 0xEF7D57))
        case "miller":
            return dressed(.dwarf, hair: 1, hairColor: 0xF0F0F0, skin: 0xEAB090, eyes: 0x5A3A26,
                           helmet: ("helm.hood", PartMaterial.cloths[0].palette, 0xFFCD75),
                           chest: ("chest.tabard", PartMaterial.cloths[0].palette, 0xFFCD75),
                           boots: ("boots.leather", PartMaterial.leathers[1].palette, 0x7A4A2A))
        case "monk":
            return dressed(.human, hair: 0, hairColor: 0x5A3A26, skin: 0xD9A07A, eyes: 0x8A5A2A,
                           helmet: ("helm.hood", PartMaterial.cloths[1].palette, 0x7A4A2A),
                           chest: ("chest.robe", PartMaterial.cloths[1].palette, 0x7A4A2A))
        case "innkeeper":
            return dressed(.human, hair: 0, hairColor: 0xC0603A, skin: 0xF0BE98, eyes: 0x3B5DC9,
                           chest: ("chest.leather", PartMaterial.leathers[1].palette, 0xF4F4F4),
                           gloves: ("gloves.leather", PartMaterial.leathers[0].palette, 0x7A4A2A),
                           boots: ("boots.leather", PartMaterial.leathers[0].palette, 0x7A4A2A))
        case "alchemist":
            return dressed(.elf, hair: 0, hairColor: 0xB89AE8, skin: 0xFCE2CC, eyes: 0xC879F2,
                           helmet: ("helm.hood", PartMaterial.cloths[3].palette, 0x5D275D),
                           chest: ("chest.robe", PartMaterial.cloths[3].palette, 0x3B5DC9))
        case "princess":
            return dressed(.human, hair: 1, hairColor: 0xE8C060, skin: 0xFAD6B8, eyes: 0x3B5DC9,
                           helmet: ("helm.circlet", PartMaterial.metals[2].palette, 0xF27AA8),
                           chest: ("chest.robe", PartMaterial.cloths[2].palette, 0xF27AA8),
                           gloves: ("gloves.wraps", PartMaterial.cloths[2].palette, 0xF4F4F4))
        case "guardCaptain":
            // Capitán Rodrigo Vela: pelo y barba corta grises, coraza de cobre abollada con tabardo azul y blanco
            // de Valdemar, capa raída y el yelmo bajo el brazo.
            return dressed(.human, hair: 0, hairColor: 0xE8E4F0, skin: 0xE0A880, eyes: 0x5A3A26,
                           chest: ("chest.plate", PartMaterial.metals[0].palette, 0x3B5DC9),
                           gloves: ("gloves.leather", PartMaterial.leathers[1].palette, 0x7A4A2A),
                           boots: ("boots.leather", PartMaterial.leathers[1].palette, 0x7A4A2A),
                           extras: LookExtras(beard: .short, hairColor: 0xA4A2AC, cape: 0x3A3F6A, capeTorn: true,
                                              heldHelmet: GearLook(styleID: "helm.knight", material: PartMaterial.metals[0].palette, dye: 0x3B5DC9),
                                              tabard: 0x3B5DC9, dented: true))
        // "letter" y "signpost" son objetos: sin versión chibi, se dibujan con `EnemyArt.objectRows`.
        default:
            return nil
        }
    }

    /// Animación en reposo (respira y parpadea), igual que el héroe quieto.
    static func idleTextures(_ look: HeroLook) -> [SKTexture] {
        [.idle0, .idle1, .idle0, .idle1, .idle2].map { Art.heroTexture($0, look: look) }
    }

    private typealias Piece = (style: String, material: [UInt32], dye: UInt32)

    private static func dressed(_ race: Race, hair: Int, hairColor: UInt32, skin: UInt32, eyes: UInt32,
                                helmet: Piece? = nil, chest: Piece? = nil, gloves: Piece? = nil, boots: Piece? = nil,
                                extras: LookExtras = LookExtras()) -> HeroLook {
        let options = HeroArt.options(for: race)
        let appearance = Appearance(skinTone: nearest(skin, in: options.skinTones),
                                    hairStyle: min(hair, options.hairStyles.count - 1),
                                    hairColor: nearest(hairColor, in: options.hairColors),
                                    eyeColor: nearest(eyes, in: options.eyeColors))
        var gear: [EquipmentSlot: GearLook] = [:]
        for (slot, piece) in [(EquipmentSlot.helmet, helmet), (.chest, chest), (.gloves, gloves), (.boots, boots)] {
            if let piece { gear[slot] = GearLook(styleID: piece.style, material: piece.material, dye: piece.dye) }
        }
        return HeroLook(race: race, appearance: appearance, gear: gear, extras: extras)
    }

    /// Índice del color de la lista más parecido (así no depende del orden de las opciones).
    private static func nearest(_ color: UInt32, in list: [UInt32]) -> Int {
        func distance(_ a: UInt32, _ b: UInt32) -> Int {
            let dr = Int((a >> 16) & 0xFF) - Int((b >> 16) & 0xFF)
            let dg = Int((a >> 8) & 0xFF) - Int((b >> 8) & 0xFF)
            let db = Int(a & 0xFF) - Int(b & 0xFF)
            return dr * dr + dg * dg + db * db
        }
        return list.indices.min { distance(list[$0], color) < distance(list[$1], color) } ?? 0
    }
}
