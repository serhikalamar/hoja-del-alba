import Foundation
import GameCore

// MARK: - Exportar los valores base para el panel de administración
//
// `Harness exportar-datos [carpeta]` (o `make datos`) escribe JSON legibles con TODOS los valores por defecto del
// código y los metadatos que necesita la web (nombres, tiers, en qué áreas sale cada monstruo, qué jefe suelta qué
// pieza…). Carpeta por defecto: `admin/public/data/`. Los valores ajustables van siempre en un objeto `base` con las
// mismas claves que el contrato `GameTuning` (assets/admin/contrato.md), para que el panel enseñe "base → ajustado".

/// Número para el JSON: entero si lo es; si no, redondeado a 4 decimales (sin restos de coma flotante).
private func num(_ v: Double) -> Any {
    let r = (v * 10_000).rounded() / 10_000
    return r == r.rounded() && abs(r) < 1e15 ? Int(r) as Any : r as Any
}

/// Estadísticas distintas de cero, por clave de `StatKind`.
private func statsJSON(_ s: Stats) -> [String: Any] {
    Dictionary(uniqueKeysWithValues: s.entries.map { ($0.kind.rawValue, num($0.value)) })
}

private func mineralsJSON(_ m: [Mineral: Int]) -> [String: Any] {
    Dictionary(uniqueKeysWithValues: m.map { ($0.key.rawValue, $0.value as Any) })
}

private func fieldJSON(_ f: TuningField) -> [String: Any] {
    ["clave": f.key, "tipo": f.integer ? "entero" : "número", "min": num(f.min), "max": num(f.max),
     "descripcion": f.description, "codigo": f.code]
}

private let behaviorNames: [EnemyBehavior: String] = [.melee: "cuerpo a cuerpo", .ranged: "a distancia", .charger: "embestida"]
private let kindNames: [AreaKind: String] = [.town: "pueblo", .interior: "interior", .field: "campo"]

func exportBaseData(to dir: URL) throws {
    // Siempre los valores del código, aunque se haya pasado `--ajustes`.
    GameTuning.apply(GameTuning())
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    func write(_ object: [String: Any], _ name: String) throws {
        var doc = object
        doc["schemaVersion"] = GameTuning.currentSchemaVersion
        doc["generado"] = "make datos (Harness exportar-datos): valores del código, no editar a mano"
        let data = try JSONSerialization.data(withJSONObject: doc, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try data.write(to: dir.appendingPathComponent(name))
        print("  → \(dir.lastPathComponent)/\(name) (\(data.count / 1024) KB)")
    }

    let areas = World.areas
    let quests = World.quests
    let dungeons = World.storyDungeons

    // Oleadas de la arena (deterministas): dónde sale cada monstruo.
    let arenaWaves = (1...100).map { Arena.wave($0) }
    var firstArenaWave: [String: Int] = [:]
    var bossWaves: [String: [Int]] = [:]
    for (i, wave) in arenaWaves.enumerated() {
        for id in wave.spawns.keys {
            if firstArenaWave[id] == nil { firstArenaWave[id] = i + 1 }
            if Bestiary.enemy(id)?.isBoss == true { bossWaves[id, default: []].append(i + 1) }
        }
    }

    // Rescates: quién da cada pieza.
    var partFromRescue: [String: String] = [:]
    for area in areas { for npc in area.npcs { if let p = npc.reward.partID { partFromRescue[p] = npc.id } } }

    // MARK: enemigos.json
    var enemies: [[String: Any]] = []
    for e in Bestiary.all {
        var base: [String: Any] = [
            "hp": num(e.hp), "damage": num(e.damage), "speed": num(e.speed), "attackCooldown": num(e.attackCooldown),
            "attackRange": num(e.attackRange), "level": e.level, "dropChance": num(e.dropChance), "dropRolls": e.dropRolls,
            "xpMultiplier": num(e.xpMultiplier), "goldMultiplier": num(e.goldMultiplier),
        ]
        if e.isBoss {
            let story = EnemyDefinition.storyBossTuning[e.id]
            base["storyHPMultiplier"] = num(story?.hp ?? 1)
            base["storyDamageMultiplier"] = num(story?.damage ?? 1)
        }
        var where_: [[String: Any]] = []
        for area in areas {
            let spawns = area.spawns.filter { $0.enemyID == e.id }
            guard !spawns.isEmpty else { continue }
            let byZone = Dictionary(grouping: spawns) { area.zone(at: $0.position)?.id ?? "" }
            for (zoneID, list) in byZone.sorted(by: { $0.key < $1.key }) {
                let zone = area.zones.first { $0.id == zoneID }
                where_.append(["area": area.id, "nombreArea": area.name, "zona": zone?.id as Any? ?? NSNull(),
                               "nombreZona": zone?.name as Any? ?? NSNull(), "nivel": zone?.level ?? area.level,
                               "spawns": list.map(\.id)])
            }
        }
        let inDungeons: [[String: Any]] = dungeons.filter { $0.enemyIDs.contains(e.id) }.map { d in
            ["id": d.id, "nombre": d.name, "nivel": d.level, "jefe": d.bossID == e.id,
             "oleadas": d.waves.enumerated().filter { $0.element[e.id] != nil }.map { $0.offset + 1 }]
        }
        var item: [String: Any] = [
            "id": e.id, "nombre": e.name, "familia": e.template, "comportamiento": e.behavior.rawValue,
            "nombreComportamiento": behaviorNames[e.behavior]!, "jefe": e.isBoss, "radio": num(e.bodyRadius),
            "escala": num(e.scale), "base": base,
            "arena": Arena.originalEnemyIDs.contains(e.id), "areas": where_, "mazmorras": inDungeons,
            "misiones": quests.filter { $0.enemyIDs.contains(e.id) }.map(\.id),
        ]
        if let first = firstArenaWave[e.id] { item["arenaPrimeraOleada"] = first }
        if let waves = bossWaves[e.id] { item["arenaOleadasDeJefe"] = waves }
        if let partID = e.specialPartID, let part = PartCatalog.part(partID) {
            item["pieza"] = ["id": part.id, "nombre": part.name]
            if let story = PartCatalog.part(partID + PartCatalog.valdemarSuffix) {
                item["piezaHistoria"] = ["id": story.id, "nombre": story.name]
            }
        }
        enemies.append(item)
    }
    try write(["enemigos": enemies, "nota": "Valores en su nivel de aparición; escalan con el nivel de la zona u oleada "
               + "(economia.json: enemyHPPerLevel…)."], "enemigos.json")

    // MARK: piezas.json
    let bossOfPart: [String: String] = Dictionary(uniqueKeysWithValues: Bestiary.bosses.compactMap { b in
        b.specialPartID.map { ($0, b.id) }
    })
    func partJSON(_ p: WeaponPart, group: String) -> [String: Any] {
        var origin: [String: Any] = ["tipo": "forja"]
        if p.isSpecial {
            let arenaID = p.id.hasSuffix(PartCatalog.valdemarSuffix) ? String(p.id.dropLast(PartCatalog.valdemarSuffix.count)) : p.id
            if let boss = bossOfPart[arenaID] {
                origin = ["tipo": p.id == arenaID ? "jefe (arena)" : "jefe (historia de Valdemar)", "jefe": boss,
                          "nombreJefe": Bestiary.enemy(boss)?.name ?? boss]
            } else if let npc = partFromRescue[p.id] {
                origin = ["tipo": "rescate", "npc": npc, "nombreNpc": World.npcShortName(npc)]
            } else {
                origin = ["tipo": "única"]
            }
        } else if let npc = partFromRescue[p.id] {
            origin = ["tipo": "forja y rescate", "npc": npc, "nombreNpc": World.npcShortName(npc)]
        }
        var item: [String: Any] = [
            "id": p.id, "nombre": p.name, "grupo": group, "hueco": p.slot.rawValue, "nombreHueco": p.slot.name,
            "forma": p.shape, "material": p.materialName, "elementos": p.elements.map(\.rawValue), "unica": p.isSpecial,
            "origen": origin, "base": ["stats": statsJSON(p.stats), "price": p.price, "tier": p.tier] as [String: Any],
        ]
        if let ability = AbilityBook.ability(p.abilityID) { item["habilidad"] = ["id": ability.id, "nombre": ability.name] }
        return item
    }
    let parts = PartCatalog.normalParts.map { partJSON($0, group: "normal") }
        + PartCatalog.specialParts.map { partJSON($0, group: "única") }
        + PartCatalog.storyBossParts.map { partJSON($0, group: "jefe de la historia") }
    let armor: [[String: Any]] = ArmorCatalog.styles.map { s in
        ["id": s.id, "nombre": s.name, "hueco": s.slot.rawValue, "nombreHueco": s.slot.name,
         "tipoMaterial": s.materialKind.rawValue, "materiales": s.materialKind.materials.map { ["id": $0.id, "nombre": $0.name, "tier": $0.tier] },
         "base": ["stats": statsJSON(s.base), "price": num(s.forgePrice)] as [String: Any]]
    }
    let materials: [[String: Any]] = (PartMaterial.metals + PartMaterial.woods + PartMaterial.leathers + PartMaterial.cloths).map { m in
        ["id": m.id, "nombre": m.name, "tier": m.tier, "poder": num(m.power), "elemento": m.element?.rawValue as Any? ?? NSNull()]
    }
    try write(["piezas": parts, "armaduras": armor, "materiales": materials,
               "nota": "Las armaduras se escalan con el material (poder) y la ruleta; los materiales no son ajustables."],
              "piezas.json")

    // MARK: minerales.json
    let minerals: [[String: Any]] = Mineral.allCases.map { m in
        let families = World.continents.filter { $0.minerals.contains(m) }.map(\.id)
        return ["id": m.rawValue, "nombre": m.name, "rareza": m.rarityTier, "continentes": families,
                "base": ["value": m.value, "dropWeight": num(m.dropPercent), "stats": statsJSON(m.buffPerUnit)] as [String: Any]]
    }
    let families: [[String: Any]] = World.continents.map { c in
        ["continente": c.id, "nombre": c.name,
         "minerales": zip(c.minerals, Continent.familyWeights).map { ["id": $0.rawValue, "peso": num($1)] as [String: Any] }]
    }
    try write(["minerales": minerals, "familias": families,
               "nota": "dropWeight solo vale para la arena; en la historia salen las familias (economy.continentLootWeights)."],
              "minerales.json")

    // MARK: zonas.json
    func spawnJSON(_ s: Spawn) -> [String: Any] {
        let e = Bestiary.enemy(s.enemyID)
        return ["id": s.id, "enemyID": s.enemyID, "nombre": e?.name ?? s.enemyID, "jefe": e?.isBoss ?? false]
    }
    let areaList: [[String: Any]] = areas.map { area in
        let zones: [[String: Any]] = area.zones.map { z in
            ["id": z.id, "nombre": z.name, "base": ["level": z.level],
             "spawns": area.spawns.filter { z.contains($0.position) }.map(spawnJSON)]
        }
        let rescues: [[String: Any]] = area.npcs.filter { area.isInterior && ($0.role == .villager || $0.role == .princess) }
            .map { ["id": $0.id, "nombre": $0.name] }
        return ["id": area.id, "nombre": area.name, "tipo": area.kind.rawValue, "nombreTipo": kindNames[area.kind]!,
                "continente": area.continentID, "base": ["level": area.level], "zonas": zones,
                "fueraDeZona": area.spawns.filter { area.zone(at: $0.position) == nil }.map(spawnJSON), "rescates": rescues,
                "mazmorras": area.dungeonEntrances.map(\.dungeonID)]
    }
    let dungeonList: [[String: Any]] = dungeons.map { d in
        ["id": d.id, "nombre": d.name, "piso": d.floorID, "area": d.entranceAreaID, "repetible": d.repeatable,
         "jefe": d.bossID as Any? ?? NSNull(), "nombreJefe": d.bossID.flatMap { Bestiary.enemy($0)?.name } as Any? ?? NSNull(),
         "base": ["level": d.level, "waves": d.waves, "bossEscort": d.bossEscort] as [String: Any]]
    }
    let arena: [[String: Any]] = arenaWaves.prefix(30).enumerated().map { i, w in
        let n = i + 1
        return ["oleada": n, "nivelEnemigos": Arena.enemyLevel(wave: n), "tier": Arena.tier(wave: n), "jefe": Arena.isBossWave(n),
                "piso": Arena.floor(wave: n).id, "oro": Arena.reward(wave: n), "forja": Arena.isShopWave(n),
                "nivelForja": Arena.isShopWave(n) ? Arena.shopLevel(wave: n) as Any : NSNull(), "spawns": w.spawns]
    }
    let continents: [[String: Any]] = World.continents.map { c in
        ["id": c.id, "nombre": c.name, "niveles": [c.levels.lowerBound, c.levels.upperBound], "tier": c.tier,
         "minerales": c.minerals.map(\.rawValue), "areas": c.areaIDs]
    }
    try write(["continentes": continents, "areas": areaList, "mazmorras": dungeonList, "arena": arena,
               "nota": "Los spawns se ajustan uno a uno (spawns.<id> = id de monstruo); los jefes no se mueven."],
              "zonas.json")

    // MARK: misiones.json
    let questList: [[String: Any]] = quests.map { q in
        ["id": q.id, "titulo": q.title, "resumen": q.summary, "daMision": q.giverID, "nombreDaMision": World.npcShortName(q.giverID),
         "objetivos": q.objectives.enumerated().map { i, o in
             (i < q.objectiveLabels.count ? q.objectiveLabels[i] : PlayerProfile.describe(o)).replacingOccurrences(of: "{n}", with: "N")
         },
         "monstruos": q.enemyIDs, "areas": q.areaIDs,
         "base": ["xp": q.reward.xp, "gold": q.reward.gold, "minerals": mineralsJSON(q.reward.minerals)] as [String: Any]]
    }
    var rescueList: [[String: Any]] = []
    for area in areas where area.isInterior {
        for npc in area.npcs where npc.role == .villager || npc.role == .princess {
            var item: [String: Any] = ["id": npc.id, "nombre": npc.name, "area": area.id, "nombreArea": area.name,
                                       "papel": npc.role == .princess ? "princesa" : "aldeano",
                                       "base": ["gold": npc.reward.gold, "minerals": mineralsJSON(npc.reward.minerals)] as [String: Any]]
            if let partID = npc.reward.partID {
                item["pieza"] = ["id": partID, "nombre": PartCatalog.part(partID)?.name ?? partID]
            }
            rescueList.append(item)
        }
    }
    try write(["misiones": questList, "rescates": rescueList], "misiones.json")

    // MARK: economia.json
    var economyBase: [String: Any] = [:]
    for entry in TuningSchema.economy { economyBase[entry.field.key] = num(entry.base) }
    economyBase["continentLootWeights"] = EconomyValues.base.continentLootWeights.map(num)
    let roulette: [[String: Any]] = Roulette.segments.map { s in
        ["id": s.id, "nombre": s.name, "rareza": s.rarity.name, "suerte": num(s.luckFactor),
         "base": ["weight": num(s.weight), "multiplier": num(s.multiplier)]]
    }
    let tables: [String: Any] = [
        "xpParaSubir": (1..<Leveling.maxLevel).map { ["nivel": $0, "xp": Leveling.xpToNext($0)] },
        "oroArenaPorOleada": (1...40).map { ["oleada": $0, "oro": Arena.reward(wave: $0)] },
        "nivelEnemigosArena": (1...40).map { ["oleada": $0, "nivel": Arena.enemyLevel(wave: $0)] },
    ]
    try write(["base": economyBase, "ruleta": roulette, "tablas": tables,
               "nota": "Las tablas se calculan con los valores base; cambian si se ajusta la economía."], "economia.json")

    // MARK: esquema.json
    func section(_ key: String, _ description: String, _ fields: [TuningField], extra: [String: Any] = [:]) -> [String: Any] {
        var s: [String: Any] = ["clave": key, "descripcion": description, "campos": fields.map(fieldJSON)]
        for (k, v) in extra { s[k] = v }
        return s
    }
    let statsField = ["stats": "mapa clave de estadística → valor final (ver `estadisticas`); solo cambian las que vienen"]
    let rewardMinerals = ["minerals": "mapa id de mineral → unidades (\(fieldJSON(TuningSchema.rewardMineral)["min"]!)-"
                          + "\(fieldJSON(TuningSchema.rewardMineral)["max"]!)); si viene, sustituye a todos"]
    let schema: [String: Any] = [
        "documento": [
            "schemaVersion": "entero: versión del formato (\(GameTuning.currentSchemaVersion))",
            "version": "entero opcional: versión publicada en el panel",
            "note": "texto opcional: nota de quien publica",
        ],
        "apartados": [
            "enemies": section("id de monstruo (enemigos.json)", "Monstruos y jefes", TuningSchema.enemy),
            "parts": section("id de pieza (piezas.json · piezas)", "Piezas de arma", TuningSchema.part, extra: ["mapas": statsField]),
            "armor": section("id de diseño (piezas.json · armaduras)", "Diseños de armadura", TuningSchema.armor, extra: ["mapas": statsField]),
            "minerals": section("id de mineral (minerales.json)", "Minerales", TuningSchema.mineral,
                                extra: ["mapas": ["stats": "mapa clave de estadística → bonificación por unidad"]]),
            "areas": section("id de área (zonas.json · areas)", "Áreas", TuningSchema.area),
            "zones": section("id de zona (zonas.json · areas[].zonas)", "Zonas", TuningSchema.zone),
            "spawns": ["clave": "id de spawn (zonas.json)", "descripcion": "Qué monstruo sale en ese punto",
                       "valor": "id de monstruo que no sea jefe; los jefes no se mueven. Si una misión de «mata N» se queda sin "
                           + "sus monstruos en su área, se deshacen los cambios de esa área"],
            "dungeons": section("id de mazmorra (zonas.json · mazmorras)", "Mazmorras de historia", TuningSchema.dungeon,
                                extra: ["mapas": [
                                    "waves": "lista de \(TuningSchema.dungeonWaves.lowerBound)-\(TuningSchema.dungeonWaves.upperBound) "
                                        + "oleadas; cada una, mapa id de monstruo → cuántos (0-40, sin jefes, al menos uno)",
                                    "bossEscort": "mapa id de monstruo → cuántos (0-40, sin jefes)",
                                ]]),
            "quests": section("id de misión (misiones.json · misiones)", "Recompensas de misión", TuningSchema.reward,
                              extra: ["mapas": rewardMinerals]),
            "rescues": section("id de aldeano o princesa (misiones.json · rescates)", "Recompensas de rescate (sin xp)",
                               TuningSchema.reward.filter { $0.key != "xp" }, extra: ["mapas": rewardMinerals]),
            "roulette": section("id de casilla (economia.json · ruleta)", "Ruleta de la forja", TuningSchema.roulette),
            "economy": [
                "descripcion": "Números globales (un solo objeto, sin ids)",
                "campos": TuningSchema.economy.map { fieldJSON($0.field) } + [
                    fieldJSON(TuningSchema.lootWeight).merging(["tipo": "lista de 5 números",
                                                                "descripcion": TuningSchema.lootWeight.description
                                                                    + " (de común a muy rara; deben sumar más de 0)"]) { $1 },
                ],
            ],
        ] as [String: Any],
        "estadisticas": StatKind.allCases.map { kind -> [String: Any] in
            var f = fieldJSON(TuningSchema.stats[kind]!)
            f["nombre"] = kind.shortName
            return f
        },
        "reglas": [
            "Todos los campos son opcionales: solo lo que viene cambia.",
            "Los ids desconocidos se ignoran y los números fuera de rango se recortan (el juego devuelve avisos).",
            "Los campos de tipo entero se redondean.",
            "Lo ya forjado o guardado no cambia: un arma conserva sus números.",
        ],
    ]
    try write(schema, "esquema.json")
}

/// `--ajustes <ruta>`: aplica un documento de ajustes antes del comando (para medir con `make balance` / `historia`).
func applyTuningArgument(root: URL) {
    let args = CommandLine.arguments
    guard let i = args.firstIndex(of: "--ajustes"), i + 1 < args.count else { return }
    var url = URL(fileURLWithPath: args[i + 1])
    if !FileManager.default.fileExists(atPath: url.path) { url = root.appendingPathComponent(args[i + 1]) }
    do {
        let tuning = try JSONDecoder().decode(GameTuning.self, from: Data(contentsOf: url))
        let warnings = GameTuning.apply(tuning)
        print("Ajustes aplicados: \(url.lastPathComponent)\(tuning.version.map { " (versión \($0))" } ?? "")")
        for w in warnings { print("  aviso: \(w)") }
    } catch {
        print("No se pudieron leer los ajustes de \(url.path): \(error)")
        exit(1)
    }
}
