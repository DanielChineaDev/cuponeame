import SwiftUI

/// Tarjetas de sección para los formularios de marca fuera de `Form`.

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
