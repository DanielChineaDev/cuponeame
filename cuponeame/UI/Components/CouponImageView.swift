import SwiftUI
import Kingfisher

/// Imagen de un cupón: catálogo local para las rutas `/defaults-…` (sin red)
/// y Kingfisher + Storage para las fotos propias del usuario.
struct CouponImageView: View {
    let path: String
    @State private var url: URL?

    var body: some View {
        if let name = ImageService.bundledName(for: path) {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            KFImage(url)
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
