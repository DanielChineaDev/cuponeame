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

    var body: some View {
        NavigationStack {
            Group {
                if store.coupons.isEmpty {
                    emptyState
                } else {
                    couponList
                }
            }
            .background(CuponColors.background)
            .navigationTitle("Cupones")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    userBadge
                }
            }
            .navigationDestination(for: String.self) { id in
                CouponDetailScreen(couponID: id)
            }
        }
    }

    // MARK: - Lista

    private var couponList: some View {
        ScrollView {
            VStack(spacing: 16) {
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
            .padding()
        }
        .searchable(text: $searchText, prompt: "Buscar cupón")
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

    private var userBadge: some View {
        HStack(spacing: 8) {
            Text(auth.userName ?? "")
                .font(.subheadline)
            AvatarView(emoji: auth.avatar, size: 32)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Sin cupones todavía",
                systemImage: "ticket",
                description: Text("Crea tu primer cupón en la pestaña Crear o empieza con el pack de ejemplo."))

            Button("Añadir pack de ejemplo") {
                Task { await store.addDefaultPack() }
            }
            .buttonStyle(BrandButtonStyle())
            .frame(maxWidth: 280)
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
