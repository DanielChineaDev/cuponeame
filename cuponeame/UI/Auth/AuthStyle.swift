import SwiftUI

/// Piezas compartidas del rediseño de login/registro: cabecera con el
/// ticket de la marca sobre gradiente, y campos con icono en tarjeta.

struct AuthHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CuponColors.brandPurple, CuponColors.brandPink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            FloatingShapes()

            VStack(spacing: 10) {
                BrandMark(width: 120)
                    .padding(.bottom, 10)
                Text(title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 260)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
        .ignoresSafeArea(edges: .top)
    }
}

/// Botones de Google y Apple con separador, para login y registro.
struct SocialAuthButtons: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                divider
                Text("o continúa con")
                    .font(.footnote)
                    .foregroundStyle(CuponColors.subtleText)
                    .fixedSize()
                divider
            }
            .padding(.vertical, 2)

            Button {
                Task { await auth.signInWithApple() }
            } label: {
                Label("Continuar con Apple", systemImage: "apple.logo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(colorScheme == .dark ? .white : .black, in: Capsule())
            .foregroundStyle(colorScheme == .dark ? .black : .white)

            Button {
                Task { await auth.signInWithGoogle() }
            } label: {
                HStack(spacing: 8) {
                    Text("G")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(CuponColors.brandStroke)
                    Text("Continuar con Google")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(CuponColors.surface, in: Capsule())
            .overlay(Capsule().stroke(CuponColors.subtleText.opacity(0.3), lineWidth: 1))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(CuponColors.subtleText.opacity(0.25))
            .frame(height: 1)
    }
}

/// Campo con icono sobre superficie redondeada.
struct AuthField<Field: View>: View {
    let icon: String
    @ViewBuilder var field: Field

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(CuponColors.brandPurple)
                .frame(width: 24)
            field
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(minHeight: 54)
        .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CuponColors.brandPurple.opacity(0.15), lineWidth: 1))
    }
}
