import SwiftUI
import Kingfisher

/// Imagen de un cupón: catálogo local para las rutas `/defaults-…` (sin red)
/// y Kingfisher + Storage para las fotos propias del usuario.
///
/// Las remotas se **redimensionan al decodificar** (DownsamplingImageProcessor):
/// pintar una foto de 1600 px en una tarjeta de 150 pt desperdicia memoria y
/// tirones de scroll. El original queda cacheado para no re-descargar.
struct CouponImageView: View {
    let path: String
    /// Tamaño máximo de decodificación en puntos (sobra para tarjeta y detalle).
    var targetSize = CGSize(width: 420, height: 280)

    @State private var url: URL?

    var body: some View {
        if let name = ImageService.bundledName(for: path) {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            KFImage(url)
                .setProcessor(DownsamplingImageProcessor(size: targetSize))
                .scaleFactor(UIScreen.main.scale)
                .cacheOriginalImage()
                .resizable()
                .placeholder {
                    ZStack {
                        CuponColors.brandGradient
                        ProgressView().tint(.white)
                    }
                }
                .scaledToFill()
                .task(id: path) {
                    url = await ImageService.shared.url(for: path)
                }
        }
    }
}
