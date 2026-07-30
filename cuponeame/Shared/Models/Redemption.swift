import Foundation
import FirebaseFirestore

/// Registro de un canjeo (colección `users/{uid}/redemptions`).
struct Redemption: Identifiable, Equatable {
    var id: String
    var couponID: String
    var title: String
    var category: String
    var date: Date

    init(id: String, couponID: String, title: String, category: String, date: Date) {
        self.id = id
        self.couponID = couponID
        self.title = title
        self.category = category
        self.date = date
    }

    init(id: String, data: [String: Any]) {
        self.init(
            id: id,
            couponID: data["couponID"] as? String ?? "",
            title: data["title"] as? String ?? "",
            category: data["category"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? data["date"] as? Date ?? Date())
    }

    var categoryIcon: String {
        CouponCategory(rawValue: category)?.icon ?? "ticket.fill"
    }
}
