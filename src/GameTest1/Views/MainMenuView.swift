import GameCore
import SwiftUI

struct MainMenuView: View {
    @Environment(GameStore.self) private var store
    @State private var confirmReset = false
    @State private var bob = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("GAME_TEST_1")
                        .font(Theme.font(38, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                    Text("Mundo 1 · Pueblo de Valdehierro")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.textDim)
                    Text("\(store.profile.race.name) · Aldeanos \(store.profile.town.rescued.count)/\(Valdehierro.villagerIDs.count) · Récord arena: \(store.profile.arenaBestWave ?? 0)")
                        .font(Theme.font(12, weight: .bold))
                        .foregroundStyle(Theme.textDim)

                    HStack(spacing: 10) {
                        Button("▶ JUGAR") { store.startTown() }
                            .buttonStyle(.pixel(Theme.green, text: .black, size: 17))
                        Button("⚔ ARENA") { store.startArena() }
                            .buttonStyle(.pixel(Theme.red, text: .white, size: 17))
                        Button("▤ INVENTARIO") { store.go(to: .inventory) }
                            .buttonStyle(.pixel(Theme.blue, text: .black, size: 17))
                    }
                    .padding(.top, 6)

                    HStack(spacing: 10) {
                        Button("Cambiar raza") { store.go(to: .race) }
                            .buttonStyle(.pixel(Theme.panelLight, size: 11))
                        Button("Reiniciar progreso") { confirmReset = true }
                            .buttonStyle(.pixel(Theme.panel, text: Theme.textDim, size: 10))
                    }
                }

                Spacer(minLength: 0)
                heroIllustration
            }

            HStack {
                MineralBar()
                Spacer()
                GoldLabel(amount: store.profile.gold, size: 20)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .confirmationDialog("¿Borrar todo el progreso?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Borrar", role: .destructive) { store.resetProgress() }
        }
        .onAppear { bob = true }
    }

    private var heroIllustration: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                PixelImage(image: Art.heroImage(armorIcon: store.profile.equippedArmor?.icon ?? "armor_tunic", race: store.profile.race), scale: 5.5)
                if let weapon = store.profile.equippedWeapon {
                    PixelImage(image: Art.itemImage(weapon), scale: weapon.partIDs != nil ? 3 : 4)
                        .rotationEffect(.degrees(20))
                        .offset(x: 26, y: -24)
                }
            }
            .offset(y: bob ? -4 : 0)
            .animation(.easeInOut(duration: 0.6).repeatForever(), value: bob)
            .padding(.trailing, 20)
            PixelImage(image: Art.enemyImage("goblin"), scale: 4)
            PixelImage(image: Art.enemyImage("goblinKing"), scale: 4)
        }
        .frame(width: 320, height: 190, alignment: .bottom)
    }
}
