import CoreGraphics
import Foundation
import GameCore

/// Hojas de arte del continente de Valdemar (pixel-artist): acólito del Eclipse con todos sus frames,
/// capitán Rodrigo Vela en chibi (reposo, carrera), objetos de pista y marcas de misión "!"/"?".
@MainActor
func valdemarArtSheets() {
    // Acólito: los frames del enemigo (paso, preparación, golpe, daño) y su proyectil.
    let acolyte = (0..<EnemyArt.frameCount).map { EnemyArt.grid(for: "eclipseAcolyte", frame: $0).makeCGImage() }
    sheet(acolyte, columns: EnemyArt.frameCount, cell: 40, scale: 7, "valdemar_acolyte")
    // Comparación con el cultista (el acólito debe verse "la Orden de verdad").
    let compare = ["cultist", "necromancer", "eclipseAcolyte", "abbot"].map { EnemyArt.grid(for: $0, frame: 0).makeCGImage() }
    sheet(compare, columns: compare.count, cell: 32, scale: 6, "valdemar_acolyte_compare")
    // Capitán en chibi: reposo, parpadeo y algunas poses (aunque como NPC solo respira).
    if let captain = NPCLooks.look("guardCaptain") {
        let poses: [HeroArt.Pose] = [.idle0, .idle1, .idle2, .run0, .run2, .hurt]
        sheet(poses.map { HeroArt.grid(captain, pose: $0).makeCGImage() }, columns: poses.count,
              cell: HeroArt.canvasWidth + 6, scale: 6, "valdemar_captain")
        sheet([HeroArt.grid(captain, pose: .idle0).makeCGImage()], columns: 1, cell: HeroArt.canvasWidth + 6, scale: 12,
              "valdemar_captain_big")
    }
    // Objetos de pista y marcas de misión.
    let objects = ["letter", "signpost"].map { EnemyArt.grid(for: "npc.\($0)", frame: 0).makeCGImage() }
    sheet(objects, columns: 2, cell: 26, scale: 8, "valdemar_objects")
    sheet([Sprites.questMarker(.offer), Sprites.questMarker(.turnIn)].map { $0.makeCGImage() },
          columns: 2, cell: 20, scale: 10, "valdemar_markers")
}
