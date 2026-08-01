import SwiftUI

/// Punto de partida de la pestaña Crear: acción principal para un cupón desde
/// cero, atajo para regalar a la pareja (o invitación a vincularse) e ideas
/// rápidas que prellenan el formulario.
struct CreateHubScreen: View {
    @Environment(AuthService.self) private var auth

    @State private var headerCollapse = ScrollCollapse()

    private let ideaColumns = [GridItem(.flexible(), spacing: 12),
                               GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    primaryCard

                    partnerCard

                    ideas
                }
                .padding(16)
            }
            .brandScrollTracking(headerCollapse)
            .background(CuponColors.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                BrandHeader("Crear", collapse: headerCollapse)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .blank:
                    CouponFormScreen(mode: .create)
                case .gift:
                    CouponFormScreen(mode: .create, startGifting: true)
                case .template(let index):
                    CouponFormScreen(mode: .create, template: CouponTemplate.all[index])
                }
            }
        }
    }

    // MARK: - Acción principal

    private var primaryCard: some View {
        NavigationLink(value: Route.blank) {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(CuponColors.brandPurple)
                    .frame(width: 52, height: 52)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Cupón nuevo")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Empieza desde cero y personalízalo")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(18)
            .background(
                LinearGradient(colors: [CuponColors.brandPurple, CuponColors.brandPink],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pareja

    @ViewBuilder
    private var partnerCard: some View {
        if let partner = auth.partnerName {
            NavigationLink(value: Route.gift) {
                infoCard(icon: "gift.fill", tint: CuponColors.brandPink,
                         title: "Regalar a \(partner)",
                         subtitle: "Crea un cupón y se lo enviamos directo")
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                PartnerScreen()
            } label: {
                infoCard(icon: "heart.circle.fill", tint: CuponColors.brandPink,
                         title: "¿Tienes pareja en la app?",
                         subtitle: "Vincúlate y podrás regalarle tus cupones")
            }
            .buttonStyle(.plain)
        }
    }

    private func infoCard(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(tint, in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CuponColors.subtleText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CuponColors.subtleText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(CuponColors.brandPurple.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Ideas

    private var ideas: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IDEAS RÁPIDAS")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CuponColors.subtleText)
                .padding(.leading, 6)

            LazyVGrid(columns: ideaColumns, spacing: 12) {
                ForEach(Array(CouponTemplate.all.enumerated()), id: \.element.id) { index, template in
                    NavigationLink(value: Route.template(index)) {
                        ideaCard(template)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func ideaCard(_ template: CouponTemplate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: template.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(CuponColors.brandStroke, in: RoundedRectangle(cornerRadius: 12))

            Text(template.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(template.shortDescription)
                .font(.caption)
                .foregroundStyle(CuponColors.subtleText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(CuponColors.brandPurple.opacity(0.1), lineWidth: 1))
    }

    private enum Route: Hashable {
        case blank
        case gift
        case template(Int)
    }
}
