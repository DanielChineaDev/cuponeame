import SwiftUI
import AppKit

// Exporta el logo de Cuponéame en PNG con fondo transparente, a partir del
// mismo diseño vectorial que usa la app (BrandMark + BrandWordmark).

let purple = Color(red: 0xAF / 255, green: 0x52 / 255, blue: 0xDE / 255)
let pink = Color(red: 0xFF / 255, green: 0x2D / 255, blue: 0x55 / 255)

var brandGradient: LinearGradient {
    LinearGradient(colors: [purple, pink], startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Ticket con muescas laterales (forma de la marca).
struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = rect.height * 0.09
        var path = Path(roundedRect: rect, cornerRadius: rect.height * 0.18)
        path.addEllipse(in: CGRect(x: rect.minX - notch, y: rect.midY - notch,
                                   width: notch * 2, height: notch * 2))
        path.addEllipse(in: CGRect(x: rect.maxX - notch, y: rect.midY - notch,
                                   width: notch * 2, height: notch * 2))
        return path
    }
}

/// Isotipo: ticket con corazón y perforación.
struct BrandMark: View {
    var width: CGFloat
    /// Ticket blanco (para fondos de color) o blanco con sombra (para claros).
    var onColor = false

    private var height: CGFloat { width * 440 / 700 }

    var body: some View {
        ZStack {
            TicketShape()
                .fill(.white, style: FillStyle(eoFill: true))
                .clipShape(RoundedRectangle(cornerRadius: height * 0.18))
                .shadow(color: .black.opacity(onColor ? 0.22 : 0.16),
                        radius: width * 0.05, y: width * 0.022)

            HStack(spacing: 0) {
                Image(systemName: "heart.fill")
                    .font(.system(size: width * 0.3))
                    .foregroundStyle(brandGradient)
                    .frame(maxWidth: .infinity)

                VStack(spacing: width * 0.037) {
                    ForEach(0..<7, id: \.self) { _ in
                        Circle()
                            .fill(purple.opacity(0.35))
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

/// Logo horizontal: isotipo + nombre.
struct HorizontalLogo: View {
    var white = false

    var body: some View {
        HStack(spacing: 60) {
            BrandMark(width: 460, onColor: white)
                .padding(.vertical, 60)
            Text("Cuponéame")
                .font(.system(size: 190, weight: .heavy, design: .rounded))
                .foregroundStyle(white ? AnyShapeStyle(.white) : AnyShapeStyle(brandGradient))
        }
        .padding(70)
    }
}

/// Logo vertical (isotipo sobre el nombre).
struct StackedLogo: View {
    var white = false

    var body: some View {
        VStack(spacing: 56) {
            BrandMark(width: 620, onColor: white)
            Text("Cuponéame")
                .font(.system(size: 200, weight: .heavy, design: .rounded))
                .foregroundStyle(white ? AnyShapeStyle(.white) : AnyShapeStyle(brandGradient))
        }
        .padding(80)
    }
}

/// Icono cuadrado con el gradiente de fondo (como el AppIcon).
struct IconLogo: View {
    var body: some View {
        ZStack {
            brandGradient
            Circle().fill(.white.opacity(0.08))
                .frame(width: 1500, height: 1500)
                .offset(x: -650, y: -690)
            Circle().fill(.white.opacity(0.07))
                .frame(width: 1220, height: 1220)
                .offset(x: 690, y: 750)
            BrandMark(width: 1380, onColor: true)
        }
        .frame(width: 2048, height: 2048)
    }
}

@MainActor
func render<V: View>(_ view: V, to name: String, scale: CGFloat = 1, opaque: Bool = false) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    renderer.isOpaque = opaque
    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("No se pudo renderizar \(name)")
    }
    let dir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
    let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
    try! png.write(to: url)
    print("OK \(name)  \(rep.pixelsWide)x\(rep.pixelsHigh)")
}

@main
struct Export {
    @MainActor
    static func main() {
        render(BrandMark(width: 1600).padding(120), to: "cuponeame-isotipo.png")
        render(HorizontalLogo(), to: "cuponeame-logo-horizontal.png")
        render(StackedLogo(), to: "cuponeame-logo-vertical.png")
        render(HorizontalLogo(white: true), to: "cuponeame-logo-horizontal-blanco.png")
        render(IconLogo(), to: "cuponeame-icono.png", opaque: true)
    }
}
