import SwiftUI

/// Piezas del rediseño para pantallas interiores: banner degradado compacto
/// y tarjetas de sección para formularios fuera de `Form`.

struct BrandBanner: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
            }
            Spacer()
            BrandMark(width: 84)
        }
        .padding(18)
        .background(
            LinearGradient(colors: [CuponColors.brandPurple, CuponColors.brandPink],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24))
    }
}

/// Sección con título pequeño y contenido en tarjeta redondeada.
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CuponColors.subtleText)
                .padding(.leading, 6)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(CuponColors.brandPurple.opacity(0.10), lineWidth: 1))
        }
    }
}
