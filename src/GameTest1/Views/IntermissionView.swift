import GameCore
import SwiftUI

/// Entre oleadas (cada 2): la forja del enano con la tienda, el ritual, la armería y la venta.
struct IntermissionView: View {
    let session: BattleSession

    var body: some View {
        ForgeShopView(shop: session.shop, hp: session.hp, maxHP: session.maxHP,
                      primaryTitle: "OLEADA \(session.wave + 1) ▶",
                      primaryAction: { session.startNextWave() }) {
            Text("OLEADA \(session.wave) ✓  +\(session.lastWaveReward) oro")
                .font(Theme.font(14, weight: .black))
                .foregroundStyle(Theme.gold)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
        }
    }
}
