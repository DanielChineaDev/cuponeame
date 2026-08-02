import SwiftUI

/// Paywall de Cuponéame Premium: compra única que quita los anuncios y
/// desbloquea las creaciones ilimitadas.
struct PremiumSheet: View {
    @Environment(MonetizationStore.self) private var monetization
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    VStack(spacing: 12) {
                        perk(icon: "infinity", title: "Cupones ilimitados",
                             detail: "Crea todos los que quieras, sin límite mensual.")
                        perk(icon: "hand.raised.fill", title: "Sin anuncios",
                             detail: "Se acabaron los intersticiales al abrir cupones.")
                        perk(icon: "heart.fill", title: "Apoyas la app",
                             detail: "Un pago único, para siempre. Sin suscripciones.")
                    }

                    if monetization.isPremium {
                        Label("Ya eres premium. ¡Gracias!", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(CuponColors.brandPink)
                            .padding(.top, 6)
                    } else {
                        buyButton

                        Button("Restaurar compras") {
                            Task { await purchases.restore() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(CuponColors.subtleText)
                    }
                }
                .padding(20)
            }
            .background(CuponColors.background)
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task { await purchases.load() }
            .onChange(of: monetization.isPremium) { _, premium in
                if premium { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            BrandMark(width: 150)
            Text("Cuponéame Premium")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
            Text("Un pago único para desbloquear la app entera.")
                .font(.subheadline)
                .foregroundStyle(CuponColors.subtleText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func perk(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(CuponColors.brandStroke, in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(CuponColors.subtleText)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(CuponColors.brandPurple.opacity(0.1), lineWidth: 1))
    }

    private var buyButton: some View {
        Button {
            Task { await purchases.buy() }
        } label: {
            if purchases.isWorking {
                ProgressView().tint(.white)
            } else if let price = purchases.priceLabel {
                Text("QUITAR ANUNCIOS · \(price)")
            } else {
                Text("QUITAR ANUNCIOS")
            }
        }
        .buttonStyle(BrandButtonStyle())
        .disabled(purchases.isWorking || !purchases.available)
        .opacity(purchases.available ? 1 : 0.6)
        .padding(.top, 6)
    }
}
