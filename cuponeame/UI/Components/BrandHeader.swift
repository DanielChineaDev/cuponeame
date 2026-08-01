import SwiftUI

/// Progreso de contracción (0 = expandida, 1 = contraída) en un objeto
/// observable: el scroll solo re-dibuja la cabecera, nunca la lista.
@Observable
final class ScrollCollapse {
    var value: CGFloat = 0
}

/// Andamiaje del patrón GasApp para cabeceras que se contraen SIN congelar el
/// scroll: el hueco superior del scroll es de altura CONSTANTE (medida por una
/// sonda invisible siempre expandida) y la cabecera viva se dibuja encima en
/// un ZStack — al contraerse solo cambia visualmente, sin recolocar la lista.
struct BrandHeaderScaffold<Content: View, Header: View>: View {
    var collapse: ScrollCollapse
    @ViewBuilder var content: () -> Content
    /// Se llama con `nil` para la sonda (expandida) y con el objeto para la viva.
    @ViewBuilder var header: (ScrollCollapse?) -> Header

    @State private var headerHeight: CGFloat = 132

    var body: some View {
        ZStack(alignment: .top) {
            content()
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: headerHeight)
                }

            // Sonda invisible: mide la altura real expandida, nada más.
            header(nil)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { report(geo.size) }
                            .onChange(of: geo.size) { _, size in report(size) }
                    }
                }

            header(collapse)
        }
    }

    /// Solo medidas con ancho real: fuera de pantalla el layout es degenerado.
    private func report(_ size: CGSize) {
        guard size.width > 300, size.height > 60,
              abs(size.height - headerHeight) > 1 else { return }
        Task { @MainActor in headerHeight = size.height }
    }
}

/// Cabecera de cristal que se contrae al hacer scroll: mini ticket, título y
/// acciones encogen; el buscador y el contenido inferior se pliegan.
struct BrandHeader<Trailing: View>: View {
    let title: String
    var searchText: Binding<String>? = nil
    /// nil = siempre expandida (sonda del andamiaje).
    var collapse: ScrollCollapse?
    var bottom: AnyView? = nil
    @ViewBuilder var trailing: Trailing

    @FocusState private var searchFocused: Bool

    private var clamped: CGFloat { min(max(collapse?.value ?? 0, 0), 1) }
    private var expanded: CGFloat { 1 - clamped }

    var body: some View {
        VStack(spacing: 12 * expanded) {
            HStack(spacing: 12) {
                BrandMark(width: 44)
                    .scaleEffect(1 - 0.32 * clamped, anchor: .leading)
                    .frame(width: 44 * (1 - 0.32 * clamped), alignment: .leading)
                Text(title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .scaleEffect(1 - 0.18 * clamped, anchor: .leading)
                Spacer()
                trailing
                    .scaleEffect(1 - 0.2 * clamped, anchor: .trailing)
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
                .frame(height: 46 * expanded)
                .background(CuponColors.searchFill, in: Capsule())
                .clipShape(Capsule())
                .opacity(expanded)
            }

            if let bottom {
                bottom
                    .frame(height: 20 * expanded, alignment: .top)
                    .clipped()
                    .opacity(expanded)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14 - 5 * clamped)
        .cuponGlass(cornerRadius: 26)
        .padding(.horizontal, 12)
        // Segura aquí: la cabecera vive en un ZStack (overlay visual), su tamaño
        // no toca los insets del scroll, así que no realimenta el layout.
        .animation(.easeOut(duration: 0.15), value: clamped)
    }
}

extension BrandHeader where Trailing == EmptyView {
    init(_ title: String, collapse: ScrollCollapse?,
         searchText: Binding<String>? = nil, bottom: AnyView? = nil) {
        self.init(title: title, searchText: searchText, collapse: collapse,
                  bottom: bottom) { EmptyView() }
    }
}

extension View {
    /// Alimenta la contracción desde el scroll (iOS 18+), como gasScrollTracking.
    @ViewBuilder
    func brandScrollTracking(_ collapse: ScrollCollapse) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, value in
                collapse.value = min(max(value / 70, 0), 1)
            }
        } else {
            self
        }
    }
}
