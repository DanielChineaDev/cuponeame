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

/// Campo con icono sobre superficie redondeada.
struct AuthField<Field: View>: View {
    let icon: String
    @ViewBuilder var field: Field

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(CuponColors.brandPurple)
                .frame(width: 24)
            field
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CuponColors.brandPurple.opacity(0.15), lineWidth: 1))
    }
}
