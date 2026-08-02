import Foundation
import Observation

/// Reglas de monetización de Cuponéame, persistidas en UserDefaults:
///
/// - **Cuota de creación**: 5 cupones propios al mes. Se recarga sola cada mes
///   natural, o al ver un anuncio bonificado (+3 creaciones).
/// - **Premium** (compra única): sin anuncios y creaciones ilimitadas.
@MainActor
@Observable
final class MonetizationStore {
    /// Cupones que se pueden crear por ciclo mensual sin premium.
    static let monthlyQuota = 5
    /// Creaciones que suma un anuncio bonificado.
    static let rewardBonus = 3
    /// Aperturas de detalle entre intersticiales.
    static let interstitialEvery = 3

    private enum Key {
        static let premium = "isPremium"
        static let used = "quotaUsed"
        static let bonus = "quotaBonus"
        static let period = "quotaPeriod"
    }

    private let defaults: UserDefaults

    private(set) var isPremium: Bool
    /// Creaciones gastadas en el ciclo actual.
    private(set) var used: Int
    /// Extra ganado con anuncios bonificados en el ciclo actual.
    private(set) var bonus: Int

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isPremium = defaults.bool(forKey: Key.premium)
        used = defaults.integer(forKey: Key.used)
        bonus = defaults.integer(forKey: Key.bonus)
        rolloverIfNeeded()
    }

    // MARK: - Cuota

    /// Creaciones disponibles ahora (Int.max si es premium).
    var remaining: Int {
        isPremium ? .max : max(0, Self.monthlyQuota + bonus - used)
    }

    var canCreate: Bool { remaining > 0 }

    /// Texto para la UI: "3 de 5 cupones este mes" / "Cupones ilimitados".
    var quotaLabel: String {
        isPremium
            ? "Cupones ilimitados"
            : "\(remaining) de \(Self.monthlyQuota + bonus) cupones este mes"
    }

    /// Descuenta una creación. Devuelve false si no quedaba cuota.
    @discardableResult
    func consumeCreation() -> Bool {
        rolloverIfNeeded()
        guard !isPremium else { return true }
        guard canCreate else { return false }
        used += 1
        defaults.set(used, forKey: Key.used)
        return true
    }

    /// Recompensa del anuncio bonificado.
    func grantReward() {
        rolloverIfNeeded()
        bonus += Self.rewardBonus
        defaults.set(bonus, forKey: Key.bonus)
    }

    /// Al cambiar de mes natural, la cuota vuelve a empezar (y el extra caduca).
    func rolloverIfNeeded(now: Date = Date()) {
        let period = Self.periodKey(for: now)
        guard defaults.string(forKey: Key.period) != period else { return }
        defaults.set(period, forKey: Key.period)
        used = 0
        bonus = 0
        defaults.set(0, forKey: Key.used)
        defaults.set(0, forKey: Key.bonus)
    }

    /// "2026-07": identificador del ciclo mensual.
    static func periodKey(for date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    // MARK: - Premium

    func setPremium(_ value: Bool) {
        isPremium = value
        defaults.set(value, forKey: Key.premium)
    }
}
