import Foundation

/// Foto fija que la app deja en el App Group para que el widget pinte el
/// próximo cupón disponible sin tocar Firebase. Compilado en app y widget.
struct WidgetSnapshot: Codable, Equatable {
    struct NextCoupon: Codable, Equatable {
        var title: String
        var category: String
        var categoryIcon: String
        var remainingUses: Int
    }

    var updated: Date
    var total: Int
    var available: Int
    var next: NextCoupon?

    static let appGroup = "group.com.bpo.cuponeame"
    static let key = "widget-snapshot"

    static func load(defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults?.set(data, forKey: Self.key)
    }
}
