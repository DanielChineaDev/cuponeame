import SwiftUI

/// Filtro rápido de la lista.
private enum CouponFilter: Equatable {
    case all
    case favorites
    case category(String)
}

struct CouponListScreen: View {
    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store

    @State private var searchText = ""
    @State private var filter: CouponFilter = .all

    private var filtered: [Coupon] {
        store.coupons.filter { coupon in
            switch filter {
            case .all: true
            case .favorites: coupon.favorite
            case .category(let category): coupon.category == category
            }
        }
        .filter { coupon in
            guard !searchText.isEmpty else { return true }
            return coupon.title.localizedCaseInsensitiveContains(searchText)
                || coupon.shortDescription.localizedCaseInsensitiveContains(searchText)
                || coupon.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    @State private var headerCollapse = ScrollCollapse()

    var body: some View {
        NavigationStack {
            BrandHeaderScaffold(collapse: headerCollapse) {
                ScrollView {
                    VStack(spacing: 16) {
                        if store.coupons.isEmpty {
                            emptyState
                                .padding(.top, 40)
                        } else {
                            filterChips

                            LazyVStack(spacing: 20) {
                                ForEach(filtered) { coupon in
                                    NavigationLink(value: coupon.id) {
                                        CouponCard(coupon: coupon)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if filtered.isEmpty {
                                Group {
                                    if searchText.isEmpty {
                                        ContentUnavailableView(
                                            "Nada por aquí",
                                            systemImage: "ticket",
                                            description: Text("No hay cupones con este filtro."))
                                    } else {
                                        ContentUnavailableView.search(text: searchText)
                                    }
                                }
                                .padding(.top, 60)
                            }
                        }
                    }
                    .padding()
                }
                .brandScrollTracking(headerCollapse)
                .scrollDismissesKeyboard(.interactively)
            } header: { collapse in
                header(collapse: collapse)
            }
            .background(CuponColors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                CouponDetailScreen(couponID: id)
            }
        }
    }

    // MARK: - Cabecera

    private var ready: Int { store.coupons.filter { $0.canRedeem() }.count }

    private func header(collapse: ScrollCollapse?) -> some View {
        BrandHeader(title: "Cupones",
                    searchText: store.coupons.isEmpty ? nil : $searchText,
                    collapse: collapse,
                    bottom: store.coupons.isEmpty ? nil : AnyView(readyBar)) {
            AvatarView(emoji: auth.avatar, size: 40)
                .overlay(Circle().stroke(CuponColors.brandStroke, lineWidth: 2))
        }
    }

    /// Barra de progreso de cupones listos, bajo el buscador.
    private var readyBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "ticket.fill")
                .font(.footnote)
                .foregroundStyle(CuponColors.brandPurple)
            Text("**\(ready)** de \(store.coupons.count) listos para canjear")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Todos", icon: "ticket.fill", value: .all)
                chip("Favoritos", icon: "heart.fill", value: .favorites)
                ForEach(store.categories, id: \.self) { category in
                    chip(category,
                         icon: CouponCategory(rawValue: category)?.icon ?? "tag.fill",
                         value: .category(category))
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func chip(_ title: String, icon: String, value: CouponFilter) -> some View {
        let selected = filter == value
        Button {
            withAnimation(.snappy) { filter = value }
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected ? .white : .primary)
        .modifier(ChipGlass(selected: selected))
    }

    // MARK: - Extras

    private var emptyState: some View {
        VStack(spacing: 16) {
            BrandMark(width: 150)
                .padding(.bottom, 12)

            Text("Sin cupones todavía")
                .font(.title3.bold())
            Text("Crea tu primer cupón en la pestaña Crear\no empieza con el pack de ejemplo.")
                .font(.subheadline)
                .foregroundStyle(CuponColors.subtleText)
                .multilineTextAlignment(.center)

            Button("Añadir pack de ejemplo") {
                Task { await store.addDefaultPack() }
            }
            .buttonStyle(BrandButtonStyle())
            .frame(maxWidth: 280)
            .padding(.top, 8)
        }
    }
}

/// Chip de cristal, teñido de rosa cuando está seleccionado.
private struct ChipGlass: ViewModifier {
    let selected: Bool

    func body(content: Content) -> some View {
        if selected {
            content.cuponGlassCapsuleTinted(CuponColors.brandPink)
        } else {
            content.cuponGlassCapsule(interactive: true)
        }
    }
}
