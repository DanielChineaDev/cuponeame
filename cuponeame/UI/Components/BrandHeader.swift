import SwiftUI

/// Progreso de contracción (0 = expandida, 1 = contraída) en un objeto
/// observable: así el scroll solo re-dibuja la cabecera y NO la lista.
@Observable
final class ScrollCollapse {
    var value: CGFloat = 0
}

/// Cabecera de cristal que se CONTRAE al hacer scroll (patrón GasHeader): el
/// mini ticket y el título encogen, y el buscador y el contenido inferior se
/// pliegan hasta desaparecer. Se fija con `.safeAreaInset(.top)` y se alimenta
/// con `.brandScrollTracking(_:)`.
///
/// Claves anti-fallos aprendidas:
/// - El progreso vive en `collapse` (@Observable), no en @State de la pantalla
///   → el scroll no re-renderiza la lista (si no, se congela).
/// - Los sub-elementos NO se quitan de la jerarquía; solo interpolan su altura
///   a 0 → el inset cambia de forma continua (si se quitan, se atasca).
/// - Sin `.animation(value:)` interna → no realimenta el layout (colgaba).
struct BrandHeader<Trailing: View>: View {
    let title: String
    var searchText: Binding<String>? = nil
    var collapse: ScrollCollapse
    var bottom: AnyView? = nil
    @ViewBuilder var trailing: Trailing

    @FocusState private var searchFocused: Bool
    @State private var bottomHeight: CGFloat = 44

    private var clamped: CGFloat { min(max(collapse.value, 0), 1) }
    private var expanded: CGFloat { 1 - clamped }

    var body: some View {
        VStack(spacing: 12 * expanded) {
            HStack(spacing: 12) {
                BrandMark(width: 44)
                    // scaleEffect (GPU) en vez de cambiar el frame: no recalcula
                    // la forma ni la sombra en cada frame de scroll.
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
                    .frame(height: bottomHeight * expanded, alignment: .top)
                    .clipped()
                    .opacity(expanded)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14 - 5 * clamped)
        .cuponGlass(cornerRadius: 26)
        .padding(.horizontal, 12)
    }
}

extension BrandHeader where Trailing == EmptyView {
    init(_ title: String, collapse: ScrollCollapse,
         searchText: Binding<String>? = nil, bottom: AnyView? = nil) {
        self.init(title: title, searchText: searchText, collapse: collapse,
                  bottom: bottom) { EmptyView() }
    }
}

extension View {
    /// Alimenta la contracción desde el scroll (iOS 18+). `contentOffset.y` es la
    /// posición absoluta de scroll (no depende del alto de la cabecera), así que
    /// no se realimenta al contraerse: la cabecera vuelve a expandir al subir.
    @ViewBuilder
    func brandScrollTracking(_ collapse: ScrollCollapse) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, value in
                // Se contrae entre 0 y 70 pt de scroll.
                let next = min(max(value / 70, 0), 1)
                if abs(next - collapse.value) > 0.01 {
                    collapse.value = next
                }
            }
        } else {
            self
        }
    }
}
