import Foundation
import FirebaseFirestore

/// Categorías conocidas. El `rawValue` es el contrato guardado en Firestore
/// ("category"), compartido con los cupones creados por versiones anteriores.
enum CouponCategory: String, CaseIterable, Identifiable {
    case romance = "Romance"
    case intimidad = "Intimidad"
    case comida = "Comida"
    case gastronomia = "Gastronomía"
    case experiencias = "Experiencias"
    case entretenimiento = "Entretenimiento"
    case chill = "Chill"
    case personalizado = "Servicio Personalizado"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .romance: "heart.fill"
        case .intimidad: "flame.fill"
        case .comida: "fork.knife"
        case .gastronomia: "wineglass.fill"
        case .experiencias: "sparkles"
        case .entretenimiento: "popcorn.fill"
        case .chill: "sofa.fill"
        case .personalizado: "wand.and.stars"
        }
    }
}

/// Un cupón canjeable. Los nombres de campo en Firestore
/// (`short_description`, `cooldownTime`…) son el contrato heredado:
/// no cambiarlos o los cupones antiguos dejarán de cargarse.
struct Coupon: Identifiable, Equatable {
    var id: String
    var title: String
    var category: String
    var description: String
    var shortDescription: String
    var imageName: String
    var used: Bool
    var cooldownTime: TimeInterval?
    var cooldownExpirationDate: Date?
    var redeemCount: Int
    var redeemLimit: Int
    var favorite: Bool
    var createdAt: Date?

    init(id: String = "",
         title: String = "",
         category: String = CouponCategory.romance.rawValue,
         description: String = "",
         shortDescription: String = "",
         imageName: String = "",
         used: Bool = false,
         cooldownTime: TimeInterval? = nil,
         cooldownExpirationDate: Date? = nil,
         redeemCount: Int = 0,
         redeemLimit: Int = 5,
         favorite: Bool = false,
         createdAt: Date? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.shortDescription = shortDescription
        self.imageName = imageName
        self.used = used
        self.cooldownTime = cooldownTime
        self.cooldownExpirationDate = cooldownExpirationDate
        self.redeemCount = redeemCount
        self.redeemLimit = redeemLimit
        self.favorite = favorite
        self.createdAt = createdAt
    }
}

// MARK: - Lógica de canjeo

extension Coupon {
    /// Quedan usos por debajo del límite.
    var isExhausted: Bool { redeemCount >= redeemLimit }

    func isOnCooldown(now: Date = Date()) -> Bool {
        guard let expiration = cooldownExpirationDate else { return false }
        return expiration > now
    }

    func remainingCooldown(now: Date = Date()) -> TimeInterval {
        guard let expiration = cooldownExpirationDate else { return 0 }
        return max(0, expiration.timeIntervalSince(now))
    }

    func canRedeem(now: Date = Date()) -> Bool {
        !isExhausted && !isOnCooldown(now: now)
    }

    /// Progreso de usos consumidos, 0…1 (para el anillo de la tarjeta).
    var progress: Double {
        guard redeemLimit > 0 else { return 0 }
        return min(1, Double(redeemCount) / Double(redeemLimit))
    }

    var categoryIcon: String {
        CouponCategory(rawValue: category)?.icon ?? "ticket.fill"
    }

    /// Código de barras estable de 10 dígitos derivado del id (djb2).
    /// No usar `hashValue`: cambia en cada arranque.
    var barcode: String {
        var hash: UInt64 = 5381
        for byte in id.utf8 { hash = hash &* 33 &+ UInt64(byte) }
        return String(format: "%010llu", hash % 10_000_000_000)
    }

    /// "hh:mm:ss" del tiempo de espera restante.
    func remainingCooldownText(now: Date = Date()) -> String {
        let interval = Int(remainingCooldown(now: now).rounded(.up))
        return String(format: "%02d:%02d:%02d", interval / 3600, interval / 60 % 60, interval % 60)
    }
}

// MARK: - Firestore

extension Coupon {
    init(id: String, data: [String: Any]) {
        self.init(
            id: id,
            title: data["title"] as? String ?? "",
            category: data["category"] as? String ?? "",
            description: data["description"] as? String ?? "",
            shortDescription: data["short_description"] as? String ?? "",
            imageName: data["imageName"] as? String ?? "",
            used: data["used"] as? Bool ?? false,
            cooldownTime: data["cooldownTime"] as? TimeInterval,
            cooldownExpirationDate: Self.date(from: data["cooldownExpirationDate"]),
            redeemCount: data["redeemCount"] as? Int ?? 0,
            redeemLimit: data["redeemLimit"] as? Int ?? 5,
            favorite: data["favorite"] as? Bool ?? false,
            createdAt: Self.date(from: data["createdAt"]))
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "title": title,
            "category": category,
            "description": description,
            "short_description": shortDescription,
            "imageName": imageName,
            "used": used,
            "redeemCount": redeemCount,
            "redeemLimit": redeemLimit,
            "favorite": favorite,
        ]
        data["cooldownTime"] = cooldownTime ?? NSNull()
        data["cooldownExpirationDate"] = cooldownExpirationDate.map(Timestamp.init(date:)) ?? NSNull()
        data["createdAt"] = Timestamp(date: createdAt ?? Date())
        return data
    }

    private static func date(from value: Any?) -> Date? {
        if let timestamp = value as? Timestamp { return timestamp.dateValue() }
        return value as? Date
    }
}
