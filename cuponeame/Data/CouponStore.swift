import Foundation
import FirebaseFirestore

/// Estado en vivo de los cupones y el historial del usuario conectado.
/// Escucha `users/{uid}/coupons` y `users/{uid}/redemptions` con listeners de
/// Firestore, así que cualquier cambio (propio o remoto) refresca la UI solo.
@MainActor
@Observable
final class CouponStore {
    private(set) var coupons: [Coupon] = []
    private(set) var redemptions: [Redemption] = []
    var errorMessage: String?

    private var uid: String?
    private var couponsListener: ListenerRegistration?
    private var redemptionsListener: ListenerRegistration?
    private var db: Firestore { Firestore.firestore() }

    /// Categorías presentes en los cupones actuales (para los chips de filtro).
    var categories: [String] {
        var seen = Set<String>()
        return coupons.compactMap { coupon in
            let category = coupon.category
            guard !category.isEmpty, seen.insert(category).inserted else { return nil }
            return category
        }.sorted()
    }

    func coupon(id: String) -> Coupon? {
        coupons.first { $0.id == id }
    }

    // MARK: - Listeners

    func attach(uid: String) {
        guard self.uid != uid else { return }
        detach()
        self.uid = uid

        couponsListener = couponsRef(uid: uid).addSnapshotListener { [weak self] snapshot, error in
            MainActor.assumeIsolated {
                guard let self else { return }
                if let error {
                    self.errorMessage = "No se pudieron cargar los cupones: \(error.localizedDescription)"
                    return
                }
                let loaded = snapshot?.documents.map { Coupon(id: $0.documentID, data: $0.data()) } ?? []
                // Orden local: los antiguos no tienen `createdAt` y un order(by:)
                // en el servidor los excluiría de la consulta.
                self.coupons = loaded.sorted {
                    ($0.createdAt ?? .distantPast, $0.title) < ($1.createdAt ?? .distantPast, $1.title)
                }
            }
        }

        redemptionsListener = db.collection("users").document(uid).collection("redemptions")
            .addSnapshotListener { [weak self] snapshot, _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    let loaded = snapshot?.documents.map { Redemption(id: $0.documentID, data: $0.data()) } ?? []
                    self.redemptions = loaded.sorted { $0.date > $1.date }
                }
            }
    }

    func detach() {
        couponsListener?.remove()
        redemptionsListener?.remove()
        couponsListener = nil
        redemptionsListener = nil
        uid = nil
        coupons = []
        redemptions = []
    }

    // MARK: - CRUD

    /// Crea (`id` vacío) o actualiza un cupón.
    func save(_ coupon: Coupon) async {
        guard let uid else { return }
        do {
            if coupon.id.isEmpty {
                var newCoupon = coupon
                newCoupon.createdAt = Date()
                _ = try await couponsRef(uid: uid).addDocument(data: newCoupon.firestoreData)
            } else {
                try await couponsRef(uid: uid).document(coupon.id)
                    .setData(coupon.firestoreData, merge: true)
            }
        } catch {
            errorMessage = "No se pudo guardar el cupón."
        }
    }

    func delete(_ coupon: Coupon) async {
        guard let uid, !coupon.id.isEmpty else { return }
        do {
            try await couponsRef(uid: uid).document(coupon.id).delete()
        } catch {
            errorMessage = "No se pudo eliminar el cupón."
        }
    }

    func toggleFavorite(_ coupon: Coupon) async {
        guard let uid, !coupon.id.isEmpty else { return }
        try? await couponsRef(uid: uid).document(coupon.id)
            .updateData(["favorite": !coupon.favorite])
    }

    // MARK: - Canjeo

    /// Marca el canjeo, arranca el cooldown y lo apunta en el historial.
    func redeem(_ coupon: Coupon) async {
        guard let uid, !coupon.id.isEmpty, coupon.canRedeem() else { return }
        let expiration = coupon.cooldownTime.map { Date().addingTimeInterval($0) }
        do {
            try await couponsRef(uid: uid).document(coupon.id).updateData([
                "used": true,
                "redeemCount": FieldValue.increment(Int64(1)),
                "cooldownExpirationDate": expiration.map(Timestamp.init(date:)) ?? NSNull(),
            ])
            _ = try await db.collection("users").document(uid).collection("redemptions").addDocument(data: [
                "couponID": coupon.id,
                "title": coupon.title,
                "category": coupon.category,
                "date": Timestamp(date: Date()),
            ])
        } catch {
            errorMessage = "No se pudo canjear el cupón."
        }
    }

    // MARK: - Pack de ejemplo

    /// Añade el pack de cupones por defecto a la cuenta (alta y restauración).
    static func seedDefaults(uid: String) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()
        let ref = db.collection("users").document(uid).collection("coupons")
        for coupon in DefaultCoupons.all {
            var seeded = coupon
            seeded.createdAt = Date()
            batch.setData(seeded.firestoreData, forDocument: ref.document())
        }
        try await batch.commit()
    }

    func addDefaultPack() async {
        guard let uid else { return }
        do {
            try await Self.seedDefaults(uid: uid)
        } catch {
            errorMessage = "No se pudo añadir el pack de cupones."
        }
    }

    private func couponsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("coupons")
    }
}
