import SwiftUI

/// Progreso de colapso (0 = arriba, 1 = con scroll) en un objeto observable:
/// así el scroll solo re-dibuja la barra compacta y NO la lista de cupones.
@Observable
final class ScrollCollapse {
    var value: CGFloat = 0
}

/// Cabecera grande de cristal (mini ticket + título, buscador y contenido
/// inferior opcionales). Va como PRIMER elemento del scroll y se desplaza con
/// el contenido; al subir, `CompactHeaderBar` aparece fijada arriba.
struct BrandHeader<Trailing: View>: View {
    let title: String
    var searchText: Binding<String>? = nil
    var bottom: AnyView? = nil
    @ViewBuilder var trailing: Trailing

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                BrandMark(width: 44)
                Text(title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Spacer()
                trailing
            }

            if let searchText {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Buscar cupón", text: searchText)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.search)
                    if !searchText.wrappedValue.isEmpty {
                        Button {
                            searchText.wrappedValue = ""
                            searchFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(CuponColors.searchFill, in: Capsule())
            }

            if let bottom {
                bottom
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cuponGlass(cornerRadius: 26)
    }
}

extension BrandHeader where Trailing == EmptyView {
    init(_ title: String, searchText: Binding<String>? = nil, bottom: AnyView? = nil) {
        self.init(title: title, searchText: searchText, bottom: bottom) { EmptyView() }
    }
}

/// Barra compacta de cristal que se fija arriba y aparece al hacer scroll.
/// Al ir en `.overlay` NO cambia los insets del scroll: nada de bucles ni
/// atascos como con un `safeAreaInset` de altura variable.
struct CompactHeaderBar<Trailing: View>: View {
    let title: String
    var collapse: ScrollCollapse
    @ViewBuilder var trailing: Trailing

    private var shown: CGFloat { min(max(collapse.value, 0), 1) }

    var body: some View {
        HStack(spacing: 12) {
            BrandMark(width: 30)
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .cuponGlass(cornerRadius: 22)
        .padding(.horizontal, 12)
        .opacity(shown)
        .allowsHitTesting(shown > 0.5)
    }
}

extension CompactHeaderBar where Trailing == EmptyView {
    init(_ title: String, collapse: ScrollCollapse) {
        self.init(title: title, collapse: collapse) { EmptyView() }
    }
}

extension View {
    /// Alimenta el colapso desde el scroll (iOS 18+). Con la cabecera dentro del
    /// scroll (sin safeAreaInset variable), `contentOffset.y + contentInsets.top`
    /// es la distancia real desde arriba (0 en reposo) y el inset es constante.
    @ViewBuilder
    func brandScrollTracking(_ collapse: ScrollCollapse) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, value in
                // Aparece la barra compacta entre 40 y 110 pt de scroll.
                let next = min(max((value - 40) / 70, 0), 1)
                if abs(next - collapse.value) > 0.02 {
                    collapse.value = next
                }
            }
        } else {
            self
        }
    }
}
