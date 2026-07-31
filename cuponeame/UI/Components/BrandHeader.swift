import SwiftUI

/// Cabecera de cristal de las pantallas principales: mini ticket + título que
/// encogen al hacer scroll, con buscador y contenido inferior opcionales que
/// se pliegan. Mismo patrón que GasHeader en GasApp; se fija con
/// `.safeAreaInset(.top)` y se alimenta con `.brandScrollTracking(_:)`.
struct BrandHeader<Trailing: View>: View {
    let title: String
    /// nil = sin buscador.
    var searchText: Binding<String>? = nil
    /// 0 = expandida, 1 = colapsada.
    var collapse: CGFloat = 0
    /// Contenido bajo el título (p. ej. la barra de "listos"); se pliega.
    var bottom: AnyView? = nil
    @ViewBuilder var trailing: Trailing

    @FocusState private var searchFocused: Bool
    @State private var bottomHeight: CGFloat = 0

    private var clamped: CGFloat { min(max(collapse, 0), 1) }

    var body: some View {
        VStack(spacing: 12 * (1 - clamped)) {
            HStack(spacing: 12) {
                BrandMark(width: 44 - 14 * clamped)
                Text(title)
                    .font(.system(size: 28 - 6 * clamped, weight: .heavy, design: .rounded))
                Spacer()
                trailing
            }

            if let searchText, clamped < 0.99 {
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
                .frame(height: 46 * (1 - clamped))
                .background(.primary.opacity(0.06), in: Capsule())
                .clipShape(Capsule())
                .opacity(1 - clamped * 1.6)
            }

            if let bottom, clamped < 0.99 {
                bottom
                    .background {
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { bottomHeight = geo.size.height }
                                .onChange(of: geo.size.height) { _, new in
                                    if clamped == 0 { bottomHeight = new }
                                }
                        }
                    }
                    .frame(height: clamped > 0 && bottomHeight > 0
                           ? max(bottomHeight * (1 - clamped), 0) : nil,
                           alignment: .top)
                    .clipped()
                    .opacity(1 - clamped * 1.6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14 - 4 * clamped)
        .cuponGlass(cornerRadius: 26)
        .padding(.horizontal, 12)
    }
}

extension BrandHeader where Trailing == EmptyView {
    init(_ title: String, searchText: Binding<String>? = nil, collapse: CGFloat = 0,
         bottom: AnyView? = nil) {
        self.init(title: title, searchText: searchText, collapse: collapse,
                  bottom: bottom) { EmptyView() }
    }
}

extension View {
    /// Alimenta el colapso de `BrandHeader` desde el scroll (iOS 18+).
    @ViewBuilder
    func brandScrollTracking(_ collapse: Binding<CGFloat>) -> some View {
        if #available(iOS 18.0, *) {
            // `contentOffset.y + contentInsets.top` es la distancia real de
            // scroll, independiente de que la cabecera (safeAreaInset) cambie de
            // alto: en reposo siempre vale 0. El umbral evita micro-actualizaciones.
            onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, value in
                let next = min(max(value / 70, 0), 1)
                if abs(next - collapse.wrappedValue) > 0.01 {
                    collapse.wrappedValue = next
                }
            }
        } else {
            self
        }
    }
}
