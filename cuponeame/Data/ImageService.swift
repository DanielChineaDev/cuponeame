import Foundation
import UIKit
import FirebaseStorage

/// Resuelve imágenes de cupones. Las rutas `/defaults-…` se sirven del catálogo
/// local (funcionan sin red); las `user-images/…` se suben a Storage y se
/// cachean sus URLs de descarga.
@MainActor
final class ImageService {
    static let shared = ImageService()

    private var urlCache: [String: URL] = [:]

    /// Nombre del asset local para la ruta, o nil si es una imagen remota.
    nonisolated static func bundledName(for path: String) -> String? {
        guard path.hasPrefix("/defaults-") else { return nil }
        let base = (path as NSString).lastPathComponent
        let name = (base as NSString).deletingPathExtension
        return UIImage(named: name) != nil ? name : nil
    }

    /// URL de descarga de Storage (con caché por sesión).
    func url(for path: String) async -> URL? {
        if let cached = urlCache[path] { return cached }
        let reference = Storage.storage().reference().child(path)
        guard let url = try? await reference.downloadURL() else { return nil }
        urlCache[path] = url
        return url
    }

    /// Sube una foto propia reescalada y devuelve su ruta en Storage.
    func uploadCouponImage(_ image: UIImage, uid: String) async throws -> String {
        let resized = image.downscaled(maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageService", code: 1)
        }
        let path = "user-images/\(uid)/\(UUID().uuidString).jpg"
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await Storage.storage().reference().child(path).putDataAsync(data, metadata: metadata)
        return path
    }
}

extension UIImage {
    /// Reduce la imagen para no subir fotos de 12 MP a Storage.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return self }
        let scale = maxDimension / largest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
