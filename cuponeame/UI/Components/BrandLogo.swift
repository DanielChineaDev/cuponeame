import SwiftUI

/// Ticket con muescas laterales: la forma de la marca (misma que el AppIcon).
struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notchRadius = rect.height * 0.09
        var path = Path(roundedRect: rect, cornerRadius: rect.height * 0.18)
        path.addEllipse(in: CGRect(x: rect.minX - notchRadius,
                                   y: rect.midY - notchRadius,
                                   width: notchRadius * 2, height: notchRadius * 2))
        path.addEllipse(in: CGRect(x: rect.maxX - notchRadius,
                                   y: rect.midY - notchRadius,
                                   width: notchRadius * 2, height: notchRadius * 2))
        return path
    }
}

/// Isotipo: ticket blanco rotado con corazón degradado y perforación.
/// `width` manda; la altura es proporcional (ratio del AppIcon).
struct BrandMark: View {
    var width: CGFloat = 220

    private var height: CGFloat { width * 440 / 700 }

    var body: some View {
        ZStack {
            TicketShape()
                .fill(.white, style: FillStyle(eoFill: true))
                .clipShape(RoundedRectangle(cornerRadius: height * 0.18))
                .shadow(color: .black.opacity(0.22), radius: width * 0.06, y: width * 0.03)

            HStack(spacing: 0) {
                Image(systemName: "heart.fill")
                    .font(.system(size: width * 0.3))
                    .foregroundStyle(CuponColors.brandStroke)
                    .frame(maxWidth: .infinity)

                VStack(spacing: width * 0.037) {
                    ForEach(0..<7, id: \.self) { _ in
                        Circle()
                            .fill(CuponColors.brandPurple.opacity(0.35))
                            .frame(width: width * 0.024, height: width * 0.024)
                    }
                }
                .padding(.trailing, width * 0.186)
            }
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(-8))
    }
}

/// Logotipo: nombre de la app con acento de corazón.
struct BrandWordmark: View {
    var size: CGFloat = 44

    var body: some View {
        Text("Cuponéame")
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
    }
}

/// Corazones y tickets flotando suavemente en la portada.
struct FloatingShapes: View {
    struct Item {
        let symbol: String
        let size: CGFloat
        let x: CGFloat        // posición relativa 0...1
        let y: CGFloat
        let duration: Double
        let delay: Double
    }

    @State private var floating = false

    private let items: [Item] = [
        Item(symbol: "heart.fill", size: 26, x: 0.12, y: 0.16, duration: 3.6, delay: 0.0),
        Item(symbol: "ticket.fill", size: 30, x: 0.85, y: 0.12, duration: 4.2, delay: 0.6),
        Item(symbol: "heart.fill", size: 16, x: 0.78, y: 0.30, duration: 3.2, delay: 1.1),
        Item(symbol: "sparkles", size: 22, x: 0.18, y: 0.38, duration: 4.0, delay: 0.3),
        Item(symbol: "heart.fill", size: 20, x: 0.90, y: 0.52, duration: 3.8, delay: 0.9),
        Item(symbol: "ticket.fill", size: 20, x: 0.08, y: 0.58, duration: 4.4, delay: 1.4),
        Item(symbol: "sparkles", size: 16, x: 0.86, y: 0.74, duration: 3.4, delay: 0.2),
        Item(symbol: "heart.fill", size: 14, x: 0.15, y: 0.80, duration: 4.1, delay: 0.7),
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Image(systemName: item.symbol)
                    .font(.system(size: item.size))
                    .foregroundStyle(.white.opacity(0.18))
                    .position(x: proxy.size.width * item.x,
                              y: proxy.size.height * item.y)
                    .offset(y: floating ? -14 : 10)
                    .animation(
                        .easeInOut(duration: item.duration)
                            .repeatForever(autoreverses: true)
                            .delay(item.delay),
                        value: floating)
            }
        }
        .onAppear { floating = true }
        .allowsHitTesting(false)
    }
}
