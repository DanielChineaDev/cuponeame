import SwiftUI

/// Tarjeta de cupón en forma de ticket: foto arriba, perforación con muescas
/// laterales (la forma de la marca) y talón inferior con los datos.
struct CouponCard: View {
    let coupon: Coupon
    @Environment(CouponStore.self) private var store

    private static let photoHeight: CGFloat = 150

    var body: some View {
        VStack(spacing: 0) {
            photo
            stub
        }
        .background(CuponColors.surface)
        .clipShape(PunchedTicketShape(notchY: Self.photoHeight),
                   style: FillStyle(eoFill: true))
        .overlay(perforation)
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }

    // MARK: - Foto

    private var photo: some View {
        CouponImageView(path: coupon.imageName)
            .grayscale(coupon.isExhausted ? 1 : 0)
            .frame(height: Self.photoHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .topLeading) {
                statusChip.padding(10)
            }
            .overlay(alignment: .topTrailing) {
                favoriteButton.padding(10)
            }
    }

    @ViewBuilder
    private var statusChip: some View {
        if coupon.isExhausted {
            photoChip("Agotado", icon: "nosign")
        } else if coupon.isOnCooldown() {
            photoChip("En espera", icon: "clock.fill")
        }
    }

    private func photoChip(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.55), in: Capsule())
    }

    private var favoriteButton: some View {
        Button {
            Task { await store.toggleFavorite(coupon) }
        } label: {
            Image(systemName: coupon.favorite ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(coupon.favorite ? CuponColors.brandPink : .black.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.9), in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Talón

    private var stub: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(coupon.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(coupon.category, systemImage: coupon.categoryIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CuponColors.brandPurple)

                    if let from = coupon.from {
                        Label("De \(from)", systemImage: "gift.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CuponColors.brandPink)
                    }
                }
                .lineLimit(1)

                if !coupon.shortDescription.isEmpty {
                    Text(coupon.shortDescription)
                        .font(.footnote)
                        .foregroundStyle(CuponColors.subtleText)
                        .lineLimit(1)
                }
            }

            Spacer()

            UsageRing(progress: coupon.progress,
                      label: "\(coupon.redeemLimit - coupon.redeemCount)",
                      onPhoto: false)
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var perforation: some View {
        TicketPerforation(y: Self.photoHeight)
    }
}

/// Línea discontinua de perforación a la altura de las muescas.
struct TicketPerforation: View {
    let y: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 18, y: y))
                path.addLine(to: CGPoint(x: proxy.size.width - 18, y: y))
            }
            .stroke(CuponColors.subtleText.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        }
        .allowsHitTesting(false)
    }
}

/// Rect redondeado con muescas laterales a la altura de la perforación
/// (recortar con `FillStyle(eoFill: true)`).
struct PunchedTicketShape: Shape {
    var notchY: CGFloat
    var cornerRadius: CGFloat = 20
    var notchRadius: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cornerRadius)
        path.addEllipse(in: CGRect(x: rect.minX - notchRadius, y: notchY - notchRadius,
                                   width: notchRadius * 2, height: notchRadius * 2))
        path.addEllipse(in: CGRect(x: rect.maxX - notchRadius, y: notchY - notchRadius,
                                   width: notchRadius * 2, height: notchRadius * 2))
        return path
    }
}

/// Anillo de usos restantes: blanco sobre foto, colores de marca sobre talón.
struct UsageRing: View {
    let progress: Double
    let label: String
    var onPhoto = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .foregroundStyle(onPhoto ? .white.opacity(0.35)
                                         : CuponColors.brandPurple.opacity(0.15))

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .foregroundStyle(onPhoto ? AnyShapeStyle(.white)
                                         : AnyShapeStyle(CuponColors.brandStroke))
                .rotationEffect(.degrees(270))
                .animation(.linear(duration: 0.2), value: progress)

            Text(label)
                .font(.caption.bold())
                .monospacedDigit()
                .foregroundStyle(onPhoto ? .white : .primary)
        }
    }
}
