import Foundation
import GameCore

// MARK: - Campos de Valdemar (bioma `valdemar`)
//
// Suelo de las áreas de campo (`AreaMap.kind == .field`): Huertos del Molino, Bosque de Robleda, Abadía de Valsombra,
// Colinas del Pedregal y Paso del Norte. Cada zona tiene un ambiente (`FieldMood`) con sus paletas y detalles; en el
// borde entre zonas las paletas se mezclan con ruido para que no haya costuras rectas.
//
// Ficheros:
// - `FieldArt.swift`: ambientes, paletas, contexto del mapa y composición del suelo por capas.
// - `FieldArt+Ground.swift`: hierba, tierra, losas, agua, hielo, puentes, mieses y salidas.
// - `FieldArt+Rock.swift`: acantilados (tapa + cara), muros en ruinas y columnas del claustro.
// - `FieldArt+Props.swift`: rocas, lápidas y tótems, tiendas, hogueras, bajadas a mazmorra y vallas.
// - `FieldArt+Trees.swift`: árboles del campo (muertos, pinos nevados, robles del bosque) y qué árbol va en cada casilla.
// - `FieldArt+Buildings.swift`: molino en ruinas, granja quemada, iglesia de la abadía, cabaña y atalaya.
// - `FieldArt+Ambience.swift`: llamas animadas, niebla, ceniza, humo y luces del campo.
extension TownArt {
    /// Ambiente de una zona de campo: decide paletas y detalles.
    enum FieldMood: Int, CaseIterable {
        case farm, burnt, river, forest, banditCamp, road, wolfDen, graveyard, cloister, monkGarden, slopes, frozen, orcCamp, pass
    }

    static func fieldMood(areaID: String, zoneID: String?) -> FieldMood {
        switch zoneID {
        case "valdemar.huertos.trigales": return .burnt
        case "valdemar.huertos.ribera": return .river
        case "valdemar.huertos.molino": return .farm
        case "valdemar.robleda.robledal": return .forest
        case "valdemar.robleda.campamento": return .banditCamp
        case "valdemar.robleda.camino": return .road
        case "valdemar.robleda.guarida": return .wolfDen
        case "valdemar.abadia.cementerio": return .graveyard
        case "valdemar.abadia.claustro": return .cloister
        case "valdemar.abadia.huerto": return .monkGarden
        case "valdemar.pedregal.laderas": return .slopes
        case "valdemar.pedregal.pozas": return .frozen
        case "valdemar.pedregal.campamento": return .orcCamp
        case "valdemar.paso.sendero": return .pass
        default: break
        }
        switch areaID {
        case "valdemar.robleda": return .forest
        case "valdemar.abadia": return .graveyard
        case "valdemar.pedregal": return .slopes
        case "valdemar.paso": return .pass
        default: return .farm
        }
    }

    /// Paletas de un ambiente (tonos de oscuro a claro).
    struct FieldLook {
        var grass: [UInt32]
        var bladeDark: UInt32
        var bladeLight: UInt32
        /// Manchas sobre la hierba: hierba seca, ceniza, hojarasca, escarcha, nieve…
        var patch: [UInt32]
        var patchAmount: Double
        var dirt: [UInt32]
        var flowers: [UInt32]
        /// Una flor suelta cada `flowerOdds` casillas (0 = ninguna).
        var flowerOdds: Int
    }

    static let fieldLooks: [FieldLook] = FieldMood.allCases.map(makeFieldLook)

    private static func makeFieldLook(_ mood: FieldMood) -> FieldLook {
        let farmDirt: [UInt32] = [0x6E5032, 0x7E5E3A, 0x8E6C44, 0x9C7A4E, 0xAA885A]
        let forestDirt: [UInt32] = [0x5A4430, 0x684E36, 0x765A3E, 0x846646, 0x92724E]
        let abbeyDirt: [UInt32] = [0x564A3C, 0x625444, 0x6E5E4C, 0x7A6A56, 0x867560]
        let rockyDirt: [UInt32] = [0x76684E, 0x847458, 0x928262, 0xA0906C, 0xAE9E78]
        switch mood {
        case .farm:
            return FieldLook(grass: [0x4D8A3F, 0x579546, 0x62A14C, 0x6DAC52, 0x79B659], bladeDark: 0x41793A, bladeLight: 0x8CC462,
                             patch: [0x7E9444, 0x8C9E4A, 0x9AA852, 0xA8B25C], patchAmount: 0.07, dirt: farmDirt,
                             flowers: [0xF4F0E8, 0xF6D45A, 0xE88AB4], flowerOdds: 5)
        case .burnt:
            return FieldLook(grass: [0x667E3A, 0x718A40, 0x7D9446, 0x899E4E, 0x95A856], bladeDark: 0x566E34, bladeLight: 0xA8B868,
                             patch: [0x4A423A, 0x5A5046, 0x6A6054, 0x7A7062], patchAmount: 0.17,
                             dirt: [0x665038, 0x745C40, 0x826848, 0x907452, 0x9C805C], flowers: [], flowerOdds: 0)
        case .river:
            return FieldLook(grass: [0x46883F, 0x509446, 0x5AA04C, 0x66AB52, 0x72B65A], bladeDark: 0x3A7638, bladeLight: 0x86C462,
                             patch: [0x3E7A3A, 0x46843E, 0x4E8E44, 0x569848], patchAmount: 0.09, dirt: farmDirt,
                             flowers: [0xF4F0E8, 0x8EC8F4, 0xF6D45A], flowerOdds: 4)
        case .forest:
            return FieldLook(grass: [0x2E6438, 0x36703E, 0x3F7C45, 0x48874B, 0x529252], bladeDark: 0x285A33, bladeLight: 0x64A05A,
                             patch: [0x5A4A2C, 0x6A5632, 0x7A623A, 0x8A7044], patchAmount: 0.11, dirt: forestDirt,
                             flowers: [0xF4F0E8, 0xC8A0E8], flowerOdds: 9)
        case .banditCamp:
            return FieldLook(grass: [0x356A3A, 0x3D7640, 0x468246, 0x4F8D4C, 0x5A9854], bladeDark: 0x2C5C34, bladeLight: 0x6AA45C,
                             patch: [0x5E4C34, 0x6C583C, 0x7A6444, 0x88704C], patchAmount: 0.18, dirt: forestDirt,
                             flowers: [], flowerOdds: 0)
        case .road:
            return FieldLook(grass: [0x386E3C, 0x417A42, 0x4A8648, 0x54914E, 0x5E9C56], bladeDark: 0x2E6036, bladeLight: 0x72AC60,
                             patch: [0x5E4E2E, 0x6E5A34, 0x7E663C, 0x8E7446], patchAmount: 0.09, dirt: forestDirt,
                             flowers: [0xF4F0E8, 0xF6D45A], flowerOdds: 7)
        case .wolfDen:
            return FieldLook(grass: [0x47703E, 0x507A44, 0x5A844A, 0x648E50, 0x6E9856], bladeDark: 0x3C6236, bladeLight: 0x82AC66,
                             patch: [0x6A665E, 0x7A766C, 0x8A857A, 0x9A9488], patchAmount: 0.18, dirt: forestDirt,
                             flowers: [], flowerOdds: 0)
        case .graveyard:
            return FieldLook(grass: [0x44613F, 0x4C6B46, 0x55754C, 0x5E7F53, 0x68895A], bladeDark: 0x3A5636, bladeLight: 0x7C9868,
                             patch: [0x6E6C4A, 0x7A7852, 0x86835A, 0x928E64], patchAmount: 0.15, dirt: abbeyDirt,
                             flowers: [0xE8E8F0, 0xB898D8], flowerOdds: 10)
        case .cloister:
            return FieldLook(grass: [0x46633F, 0x4E6D46, 0x57774C, 0x608153, 0x6A8B5A], bladeDark: 0x3A5636, bladeLight: 0x7E9A68,
                             patch: [0x6A6860, 0x787568, 0x868272, 0x948F7E], patchAmount: 0.12, dirt: abbeyDirt,
                             flowers: [0xE8E8F0], flowerOdds: 12)
        case .monkGarden:
            return FieldLook(grass: [0x4A6A3E, 0x527444, 0x5B7E4A, 0x648850, 0x6E9257], bladeDark: 0x3E5C36, bladeLight: 0x84A466,
                             patch: [0x3A5834, 0x42623A, 0x4A6C40, 0x527646], patchAmount: 0.13, dirt: abbeyDirt,
                             flowers: [0xA884D0, 0xE8E0F0, 0xF2D25A], flowerOdds: 4)
        case .slopes:
            return FieldLook(grass: [0x6E8640, 0x7A9046, 0x869A4C, 0x92A454, 0x9EAE5C], bladeDark: 0x5E7438, bladeLight: 0xB4C070,
                             patch: [0x857C6A, 0x948A76, 0xA29882, 0xB0A690], patchAmount: 0.15, dirt: rockyDirt,
                             flowers: [0xF6D45A, 0xF4F0E8], flowerOdds: 9)
        case .frozen:
            return FieldLook(grass: [0x5A7C60, 0x648668, 0x6E9071, 0x789A7A, 0x84A485], bladeDark: 0x506E60, bladeLight: 0xA8C8B8,
                             patch: [0x8CA8B0, 0xA0B8C0, 0xB4C8D0, 0xC8D8E0], patchAmount: 0.13,
                             dirt: [0x6E6A62, 0x7A766C, 0x868276, 0x928E82, 0x9E9A8E], flowers: [], flowerOdds: 0)
        case .orcCamp:
            return FieldLook(grass: [0x627A3C, 0x6C8442, 0x768E48, 0x80984E, 0x8AA256], bladeDark: 0x546A34, bladeLight: 0xA0B266,
                             patch: [0x5A4632, 0x684F38, 0x765A40, 0x846648], patchAmount: 0.22,
                             dirt: [0x6A5038, 0x785A3E, 0x866646, 0x94724E, 0xA07E58], flowers: [], flowerOdds: 0)
        case .pass:
            return FieldLook(grass: [0x4A7658, 0x528060, 0x5B8A68, 0x649470, 0x6E9E79], bladeDark: 0x406A4E, bladeLight: 0x8EBC94,
                             patch: [0xBCCAD8, 0xD0DAE6, 0xE2EAF2, 0xF2F6FA], patchAmount: 0.05,
                             dirt: [0x6A6058, 0x786C62, 0x86786C, 0x948678, 0xA29484], flowers: [0x8E9AF0, 0xC890E0, 0xF4F0E8], flowerOdds: 7)
        }
    }

    // MARK: - Contexto

    /// Materiales del suelo para unir bordes.
    enum FieldMaterial: UInt8 { case grass = 0, dirt, water, slab, cliff }

    /// Datos del mapa precalculados (las casillas, el ambiente de cada casilla y los campos de material para
    /// redondear orillas y caminos).
    struct FieldContext {
        let map: AreaMap
        let w: Int, h: Int
        let tiles: [Tile]
        var covered: [Bool]
        var moods: [FieldMood]
        /// 1 donde hay agua (o puente), tierra (camino, salida, puente) o losas; 0 fuera. Se interpolan entre casillas.
        var waterField: [Float], dirtField: [Float], slabField: [Float]
        var nearWater: [Bool], nearDirt: [Bool], nearSlab: [Bool]
        let areaMood: FieldMood

        init(_ map: AreaMap) {
            self.map = map
            w = map.width; h = map.height
            var t: [Tile] = []
            t.reserveCapacity(w * h)
            for row in map.rows {
                let chars = Array(row)
                for x in 0..<w { t.append(x < chars.count ? (Tile(rawValue: chars[x]) ?? .grass) : .tree) }
            }
            tiles = t
            covered = Array(repeating: false, count: w * h)
            for b in map.buildings {
                for y in b.y..<(b.y + b.height) { for x in b.x..<(b.x + b.width) where x >= 0 && y >= 0 && x < w && y < h { covered[y * w + x] = true } }
            }
            areaMood = TownArt.fieldMood(areaID: map.id, zoneID: nil)
            moods = Array(repeating: areaMood, count: w * h)
            waterField = Array(repeating: 0, count: w * h)
            dirtField = waterField; slabField = waterField
            for y in 0..<h {
                for x in 0..<w {
                    let i = y * w + x
                    moods[i] = TownArt.fieldMood(areaID: map.id, zoneID: map.zone(at: TilePoint(x, y))?.id)
                    switch t[i] {
                    case .water: waterField[i] = 1
                    case .bridge: waterField[i] = 1; dirtField[i] = 1
                    case .dirt, .areaExit: dirtField[i] = 1
                    case .plaza, .cave: slabField[i] = 1
                    case .pillar where Self.slabNeighbors(t, w, h, x, y) >= 1: slabField[i] = 1
                    default: break
                    }
                }
            }
            let w = self.w, h = self.h
            func near(_ f: [Float]) -> [Bool] {
                var out = Array(repeating: false, count: w * h)
                for y in 0..<h {
                    for x in 0..<w {
                        var any = false
                        for dy in -1...1 { for dx in -1...1 {
                            let xx = min(w - 1, max(0, x + dx)), yy = min(h - 1, max(0, y + dy))
                            if f[yy * w + xx] > 0 { any = true }
                        } }
                        out[y * w + x] = any
                    }
                }
                return out
            }
            let wf = waterField, df = dirtField, sf = slabField
            nearWater = near(wf); nearDirt = near(df); nearSlab = near(sf)
        }

        private static func slabNeighbors(_ t: [Tile], _ w: Int, _ h: Int, _ x: Int, _ y: Int) -> Int {
            var n = 0
            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                let xx = x + dx, yy = y + dy
                guard xx >= 0, yy >= 0, xx < w, yy < h else { continue }
                if t[yy * w + xx] == .plaza { n += 1 }
            }
            return n
        }

        /// Casilla con las coordenadas recortadas al mapa (fuera del borde se repite la del borde).
        func tile(_ x: Int, _ y: Int) -> Tile { tiles[min(h - 1, max(0, y)) * w + min(w - 1, max(0, x))] }
        func mood(_ x: Int, _ y: Int) -> FieldMood { moods[min(h - 1, max(0, y)) * w + min(w - 1, max(0, x))] }
        func look(_ x: Int, _ y: Int) -> FieldLook { TownArt.fieldLooks[mood(x, y).rawValue] }
        func isCovered(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && covered[y * w + x] }

        /// Valor del campo interpolado entre centros de casilla en un pixel.
        func sample(_ f: [Float], _ px: Int, _ py: Int) -> Double {
            let T = Double(TownArt.tile)
            let fx = (Double(px) + 0.5) / T - 0.5, fy = (Double(py) + 0.5) / T - 0.5
            let fx0 = floor(fx), fy0 = floor(fy)
            let tx = fx - fx0, ty = fy - fy0
            let x0 = min(w - 1, max(0, Int(fx0))), y0 = min(h - 1, max(0, Int(fy0)))
            let x1 = min(w - 1, max(0, Int(fx0) + 1)), y1 = min(h - 1, max(0, Int(fy0) + 1))
            let a = Double(f[y0 * w + x0]), b = Double(f[y0 * w + x1]), c = Double(f[y1 * w + x0]), d = Double(f[y1 * w + x1])
            let top = a + (b - a) * tx, bottom = c + (d - c) * tx
            return top + (bottom - top) * ty
        }
    }

    // MARK: - Composición

    static func fieldGround(_ map: AreaMap) -> PixelGrid {
        let T = tile
        let ctx = FieldContext(map)
        var g = PixelGrid(width: ctx.w * T, height: ctx.h * T)
        var mat = [UInt8](repeating: 0, count: g.width * g.height)

        // 1. Materiales base, pixel a pixel
        fieldMaterials(&g, &mat, ctx)
        // 2. Relieve de los bordes (la hierba es más alta que el camino), orillas
        fieldEdges(&g, mat, ctx)
        // 3. Detalles de cada casilla: matas, flores, hojarasca, piedras, charcos…
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where !ctx.covered[y * ctx.w + x] {
                fieldTileDetails(&g, mat, ctx, x, y)
            }
        }
        // 4. Agua: corriente, nenúfares, juncos; puentes encima
        fieldWaterDetails(&g, mat, ctx)
        // 5. Mieses, hierba alta y maleza (de arriba abajo: las espigas de abajo tapan a las de arriba)
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where ctx.tile(x, y) == .tallGrass && !ctx.covered[y * ctx.w + x] {
                tallGrassTile(&g, ctx, x, y)
            }
        }
        // 6. Acantilados (tapa y cara)
        fieldCliffs(&g, ctx)
        // 7. Sombras proyectadas
        fieldShadows(&g, ctx)
        // 8. Luz de las hogueras y resplandor de las bajadas
        for y in 0..<ctx.h {
            for x in 0..<ctx.w {
                switch ctx.tile(x, y) {
                case .campfire: firePool(&g, x * T + T / 2, y * T + T / 2 + 4, color: campfireKind(ctx, x, y) == .eclipse ? (1.10, 0.92, 1.22) : (1.30, 1.12, 0.90), radius: 46)
                case .cave where ctx.tile(x - 1, y) != .cave:
                    let wide = ctx.tile(x + 1, y) == .cave
                    firePool(&g, x * T + (wide ? T : T / 2), y * T + T / 2, color: (1.10, 0.94, 1.26), radius: wide ? 40 : 30)
                default: break
                }
            }
        }
        // 9. Objetos del suelo, fila a fila (lo de abajo tapa a lo de arriba)
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where !ctx.covered[y * ctx.w + x] {
                fieldObject(&g, ctx, x, y)
            }
        }
        // 10. Bruma de las salidas
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where ctx.tile(x, y) == .areaExit { exitMist(&g, ctx, x, y) }
        }
        return g
    }

    /// Objeto sólido o plano de una casilla (los árboles son sprites aparte).
    private static func fieldObject(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let seed = hash(x, y, 701)
        switch ctx.tile(x, y) {
        case .wall: ruinedWallTile(&g, ctx, x, y)
        case .pillar: cloisterColumn(&g, ox, oy, seed: seed, onSlab: ctx.tile(x, y - 1) == .plaza || ctx.tile(x + 1, y) == .plaza)
        case .rock: boulder(&g, ctx, x, y)
        case .grave: graveTile(&g, ctx, x, y)
        case .tent: tentTile(&g, ctx, x, y)
        case .campfire: campfireBase(&g, ox, oy, kind: campfireKind(ctx, x, y), seed: seed)
        case .cave where ctx.tile(x - 1, y) != .cave:
            caveStairs(&g, ox, oy, width: ctx.tile(x + 1, y) == .cave ? 2 * T : T, violet: true, seed: seed)
        case .fence: fieldFence(&g, ctx, x, y)
        case .crates: crates(&g, ox, oy, kind: hash(x, y, 502))
        case .bush: fieldBush(&g, ctx, x, y)
        case .lamp: break
        default: break
        }
    }

    /// Luz cálida (o violeta) pintada en el suelo: más clara cerca, tramada en el borde.
    static func firePool(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, color: (Double, Double, Double), radius: Int) {
        let ry = radius * 6 / 10
        for y in -ry...ry {
            for x in -radius...radius {
                let d = (Double(x * x) / Double(radius * radius) + Double(y * y) / Double(ry * ry)).squareRoot()
                guard d < 1 else { continue }
                if d > 0.72 && (x + y) % 2 != 0 { continue }
                let k = (1 - d) * (1 - d) * 0.9 + (1 - d) * 0.12
                tint(&g, cx + x, cy + y, (1 + (color.0 - 1) * k, 1 + (color.1 - 1) * k, 1 + (color.2 - 1) * k))
            }
        }
    }
}
