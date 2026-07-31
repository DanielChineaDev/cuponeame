import SwiftUI

/// Paleta de Cuponéame: la marca es el gradiente morado→rosa sobre fotos,
/// con chips blancos y cristal. Roles adaptativos para claro/oscuro.
enum CuponColors {
    // Marca
    static let brandPurple = Color(hex: 0xAF52DE)
    static let brandPink = Color(hex: 0xFF2D55)

    // Roles adaptativos
    static let background = adaptive(light: 0xFAF7FC, dark: 0x140F1A)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x1D1626)
    static let subtleText = adaptive(light: 0x6B6470, dark: 0xA9A1B0)
    /// Relleno fijo del buscador (no depende de .primary, que parpadea al enfocar).
    static let searchFill = adaptive(light: 0xEFEAF2, dark: 0x2A2233)

    /// Gradiente de marca (botones destacados, fondos de auth).
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brandPurple.opacity(0.85), brandPink.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }

    /// Variante horizontal (bordes de campos, botones anchos).
    static var brandStroke: LinearGradient {
        LinearGradient(
            colors: [brandPurple.opacity(0.8), brandPink.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing)
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
    }
}

// MARK: - Apariencia

/// Tema elegido en Ajustes (persistido en @AppStorage("appTheme")).
enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Sistema"
        case .light: "Claro"
        case .dark: "Oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - Estilos de la marca

/// Botón principal: cápsula con el gradiente morado→rosa.
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(CuponColors.brandStroke)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Botón de cristal para las pantallas con foto de fondo (bienvenida).
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .cuponGlass(cornerRadius: 24)
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Campo de texto con el borde de gradiente característico de Cuponéame.
struct BrandFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(CuponColors.brandStroke, lineWidth: 2))
    }
}

extension View {
    func brandField() -> some View { modifier(BrandFieldModifier()) }
}
