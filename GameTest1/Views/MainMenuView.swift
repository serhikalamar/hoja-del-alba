import GameCore
import SwiftUI

struct MainMenuView: View {
    @Environment(GameStore.self) private var store
    @State private var confirmReset = false
    @State private var bob = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("GAME_TEST_1")
                        .font(Theme.font(38, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: .black, radius: 0, x: 3, y: 3)
                    Text("Mundo 1 · \(store.world.name)")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.textDim)
                    Text("Nivel \(store.profile.highestUnlockedLevel)/\(store.world.levels.count) desbloqueado")
                        .font(Theme.font(12, weight: .bold))
                        .foregroundStyle(Theme.textDim)

                    HStack(spacing: 10) {
                        Button("▶ JUGAR") { store.go(to: .worldMap) }
                            .buttonStyle(.pixel(Theme.green, text: .black, size: 18))
                        Button("⚒ FORJA") { store.go(to: .forge) }
                            .buttonStyle(.pixel(Theme.orange, text: .black, size: 18))
                        Button("⛨ EQUIPO") { store.go(to: .equipment) }
                            .buttonStyle(.pixel(Theme.blue, text: .black, size: 18))
                    }
                    .padding(.top, 8)

                    Button("Reiniciar progreso") { confirmReset = true }
                        .buttonStyle(.pixel(Theme.panel, text: Theme.textDim, size: 10))
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
        ZStack(alignment: .bottom) {
            PixelImage(image: Art.treeImage, scale: 6)
                .offset(x: 70, y: -20)
                .opacity(0.9)
            HStack(alignment: .bottom, spacing: 6) {
                PixelImage(image: Art.knightImage(armorIcon: store.profile.equippedArmor?.icon ?? "armor_tunic"), scale: 7)
                    .offset(y: bob ? -4 : 0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(), value: bob)
                PixelImage(image: Art.goblinImage(.goblin), scale: 5)
                PixelImage(image: Art.goblinImage(.goblinBrute), scale: 6)
            }
        }
        .frame(width: 300, height: 190, alignment: .bottom)
    }
}
