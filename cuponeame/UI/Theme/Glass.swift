import SwiftUI

// Liquid Glass (iOS 26) con fallback a materiales en iOS 17-25.
// Los componentes estándar (tab bar, toolbars, sheets) ya lo adoptan solos al
// compilar con el SDK de iOS 26; estos helpers son para superficies propias.

extension View {
    /// Panel de cristal con esquinas redondeadas (tarjetas, botones anchos).
    @ViewBuilder
    func cuponGlass(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    /// Cápsula de cristal (chips de filtros, botones flotantes).
    @ViewBuilder
    func cuponGlassCapsule(interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: .capsule)
        } else {
            self.background(.regularMaterial, in: Capsule())
        }
    }

    /// Círculo de cristal (botones de icono sobre fotos).
    @ViewBuilder
    func cuponGlassCircle() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .circle)
        } else {
            self.background(.regularMaterial, in: Circle())
        }
    }

    /// Cápsula de cristal teñida con el color de marca (chip seleccionado).
    @ViewBuilder
    func cuponGlassCapsuleTinted(_ color: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(color).interactive(), in: .capsule)
        } else {
            self.background(color.opacity(0.9), in: Capsule())
        }
    }
}
