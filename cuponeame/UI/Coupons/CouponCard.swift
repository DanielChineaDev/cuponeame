import SwiftUI

/// Tarjeta de cupón: foto a sangre con chips blancos, corazón de favorito y
/// anillo de usos. El lenguaje visual clásico de Cuponéame.
struct CouponCard: View {
    let coupon: Coupon
    @Environment(CouponStore.self) private var store

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(coupon.title)
                        .font(.title3.bold())
                        .chipBackground()

                    Label(coupon.category, systemImage: coupon.categoryIcon)
                        .font(.subheadline)
                        .chipBackground()

                    if let from = coupon.from {
                        Label("De \(from)", systemImage: "gift.fill")
                            .font(.footnote.bold())
                            .chipBackground()
                    }

                    Spacer()

                    statusChip
                }

                Spacer()

                VStack {
                    Button {
                        Task { await store.toggleFavorite(coupon) }
                    } label: {
                        Image(systemName: coupon.favorite ? "heart.fill" : "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(coupon.favorite ? CuponColors.brandPink : .black)
                            .padding(12)
                            .background(Color.white.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    UsageRing(progress: coupon.progress, label: "\(coupon.redeemLimit - coupon.redeemCount)")
                        .frame(width: 36, height: 36)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 230, maxHeight: 230)
        .background(
            CouponImageView(path: coupon.imageName)
                .grayscale(coupon.isExhausted ? 1 : 0))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    @ViewBuilder
    private var statusChip: some View {
        if coupon.isExhausted {
            Label("Agotado", systemImage: "nosign")
                .font(.footnote.bold())
                .chipBackground()
        } else if coupon.isOnCooldown() {
            Label("En espera", systemImage: "clock.fill")
                .font(.footnote.bold())
                .chipBackground()
        } else if !coupon.shortDescription.isEmpty {
            Text(coupon.shortDescription)
                .font(.footnote)
                .lineLimit(1)
                .chipBackground()
        }
    }
}

/// Anillo de usos restantes sobre la foto.
struct UsageRing: View {
    let progress: Double
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .opacity(0.35)
                .foregroundStyle(.white)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(270))
                .animation(.linear(duration: 0.2), value: progress)

            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
    }
}

private extension View {
    /// Chip blanco translúcido sobre foto (marca de la casa).
    func chipBackground() -> some View {
        self
            .padding(8)
            .background(Color.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.black)
    }
}
