import Foundation
import FirebaseFirestore
import WidgetKit

/// Estado en vivo de los cupones y el historial del usuario conectado.
/// Escucha `users/{uid}/coupons` y `users/{uid}/redemptions` con listeners de
/// Firestore, así que cualquier cambio (propio o remoto) refresca la UI solo.
@MainActor
@Observable
final class CouponStore {
    private(set) var coupons: [Coupon] = [] {
        didSet { publishWidgetSnapshot() }
    }
    private(set) var redemptions: [Redemption] = []
    /// Modo demo: todo opera sobre datos locales, sin tocar Firestore.
    private(set) var isDemo = false
    /// Último regalo recibido y aún no anunciado (dispara el aviso en la UI).
    var incomingGift: Coupon?
    var errorMessage: String?

    private var uid: String?
    /// IDs ya vistos: los cupones nuevos con `from` que no estén aquí son regalos.
    private var knownCouponIDs: Set<String>?
    /// Último snapshot publicado al widget, para no repintar sin cambios.
    private var lastWidgetSnapshot: WidgetSnapshot?
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

    /// Deja en el App Group lo que el widget necesita y recarga sus timelines.
    /// Solo publica si algo relevante cambió: el listener refresca a menudo y
    /// no tiene sentido repintar el widget cada vez.
    private func publishWidgetSnapshot() {
        let available = coupons.filter { $0.canRedeem() }
        let next = available.first.map {
            WidgetSnapshot.NextCoupon(
                title: $0.title,
                category: $0.category,
                categoryIcon: $0.categoryIcon,
                remainingUses: max(0, $0.redeemLimit - $0.redeemCount))
        }
        let snapshot = WidgetSnapshot(updated: Date(), total: coupons.count,
                                      available: available.count, next: next)
        if let last = lastWidgetSnapshot,
           last.total == snapshot.total,
           last.available == snapshot.available,
           last.next == snapshot.next {
            return
        }
        lastWidgetSnapshot = snapshot
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
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
                let sorted = loaded.sorted {
                    ($0.createdAt ?? .distantPast, $0.title) < ($1.createdAt ?? .distantPast, $1.title)
                }
                // El primer snapshot solo siembra los IDs; a partir de ahí,
                // un cupón nuevo firmado con `from` es un regalo de la pareja.
                if let known = self.knownCouponIDs,
                   let gift = sorted.last(where: { $0.from != nil && !known.contains($0.id) }) {
                    self.incomingGift = gift
                    NotificationService.shared.notifyIncomingGift(gift)
                }
                self.knownCouponIDs = Set(sorted.map(\.id))
                self.coupons = sorted
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
        isDemo = false
        coupons = []
        redemptions = []
        knownCouponIDs = nil
        incomingGift = nil
    }

    // MARK: - Modo demo

    /// Siembra el pack de ejemplo en memoria con estados variados
    /// (favorito, en espera, agotado) para poder probar toda la UI sin cuenta.
    func attachDemo() {
        detach()
        isDemo = true
        uid = "demo"

        var seeded: [Coupon] = []
        for (index, coupon) in DefaultCoupons.all.enumerated() {
            var demo = coupon
            demo.id = "demo-\(index)"
            demo.createdAt = Date().addingTimeInterval(TimeInterval(index))
            seeded.append(demo)
        }
        // Beso: favorito con usos gastados. Cerveza: en espera. Cine: agotado.
        seeded[2].favorite = true
        seeded[2].redeemCount = 2
        seeded[8].used = true
        seeded[8].redeemCount = 1
        seeded[8].cooldownExpirationDate = Date().addingTimeInterval(7200)
        seeded[10].used = true
        seeded[10].redeemCount = seeded[10].redeemLimit
        coupons = seeded
        knownCouponIDs = Set(seeded.map(\.id))

        redemptions = [
            Redemption(id: "demo-r0", couponID: "demo-2", title: "Beso", category: "Romance",
                       date: Date().addingTimeInterval(-3600)),
            Redemption(id: "demo-r1", couponID: "demo-8", title: "Cerveza", category: "Gastronomía",
                       date: Date().addingTimeInterval(-90000)),
        ]
    }

    // MARK: - CRUD

    /// Crea (`id` vacío) o actualiza un cupón.
    func save(_ coupon: Coupon) async {
        guard let uid else { return }
        if isDemo {
            if coupon.id.isEmpty {
                var newCoupon = coupon
                newCoupon.id = "demo-\(UUID().uuidString)"
                newCoupon.createdAt = Date()
                coupons.append(newCoupon)
            } else if let index = coupons.firstIndex(where: { $0.id == coupon.id }) {
                coupons[index] = coupon
            }
            return
        }
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
        if isDemo {
            coupons.removeAll { $0.id == coupon.id }
            return
        }
        do {
            try await couponsRef(uid: uid).document(coupon.id).delete()
        } catch {
            errorMessage = "No se pudo eliminar el cupón."
        }
    }

    func toggleFavorite(_ coupon: Coupon) async {
        guard let uid, !coupon.id.isEmpty else { return }
        if isDemo {
            if let index = coupons.firstIndex(where: { $0.id == coupon.id }) {
                coupons[index].favorite.toggle()
            }
            return
        }
        try? await couponsRef(uid: uid).document(coupon.id)
            .updateData(["favorite": !coupon.favorite])
    }

    // MARK: - Canjeo

    /// Marca el canjeo, arranca el cooldown y lo apunta en el historial.
    func redeem(_ coupon: Coupon) async {
        guard let uid, !coupon.id.isEmpty, coupon.canRedeem() else { return }
        let expiration = coupon.cooldownTime.map { Date().addingTimeInterval($0) }
        // Aviso local para cuando el cooldown termine (si hay permiso).
        if let expiration, coupon.redeemCount + 1 < coupon.redeemLimit {
            NotificationService.shared.scheduleCooldownEnd(for: coupon, at: expiration)
        }
        if isDemo {
            if let index = coupons.firstIndex(where: { $0.id == coupon.id }) {
                coupons[index].used = true
                coupons[index].redeemCount += 1
                coupons[index].cooldownExpirationDate = expiration
            }
            redemptions.insert(
                Redemption(id: "demo-\(UUID().uuidString)", couponID: coupon.id,
                           title: coupon.title, category: coupon.category, date: Date()),
                at: 0)
            return
        }
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

    // MARK: - Regalar (modo pareja)

    /// Envía una copia limpia del cupón al talonario de la pareja, firmada
    /// con el nombre de quien lo regala (campo `from`).
    @discardableResult
    func gift(_ coupon: Coupon, to partnerUID: String, from senderName: String) async -> Bool {
        var gifted = coupon
        gifted.id = ""
        gifted.from = senderName
        gifted.used = false
        gifted.redeemCount = 0
        gifted.cooldownExpirationDate = nil
        gifted.favorite = false
        gifted.createdAt = Date()
        if isDemo {
            // En demo, Pao devuelve el detalle a los pocos segundos 💜 (así se
            // puede probar el aviso de regalo entrante sin segunda cuenta).
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard let self, self.isDemo else { return }
                var reply = DefaultCoupons.all.randomElement() ?? gifted
                reply.id = "demo-\(UUID().uuidString)"
                reply.from = "Pao"
                reply.createdAt = Date()
                self.coupons.append(reply)
                self.knownCouponIDs?.insert(reply.id)
                self.incomingGift = reply
            }
            return true
        }
        do {
            _ = try await db.collection("users").document(partnerUID)
                .collection("coupons").addDocument(data: gifted.firestoreData)
            return true
        } catch {
            errorMessage = "No se pudo enviar el cupón."
            return false
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
        if isDemo {
            for coupon in DefaultCoupons.all {
                var demo = coupon
                demo.id = "demo-\(UUID().uuidString)"
                demo.createdAt = Date()
                coupons.append(demo)
            }
            return
        }
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
