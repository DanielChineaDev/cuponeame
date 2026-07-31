import Foundation
import UserNotifications

/// Notificaciones locales: aviso de regalo entrante y recordatorio de cupón
/// disponible tras el cooldown. (La push remota con la app cerrada del todo
/// necesita Cloud Functions + APNs; sigue en el roadmap.)
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private var center: UNUserNotificationCenter { .current() }

    @discardableResult
    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// «Te ha llegado un regalo»: inmediata, al detectar el cupón con `from`.
    /// En primer plano no hace falta banner (la app ya muestra su alerta).
    func notifyIncomingGift(_ coupon: Coupon) {
        let content = UNMutableNotificationContent()
        content.title = "Te ha llegado un regalo"
        content.body = "\(coupon.from ?? "Tu pareja") te ha enviado «\(coupon.title)»."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "gift-\(coupon.id)",
                                         content: content, trigger: nil))
    }

    /// «Ya puedes volver a canjearlo»: programada al canjear con cooldown.
    func scheduleCooldownEnd(for coupon: Coupon, at date: Date) {
        let seconds = date.timeIntervalSinceNow
        guard seconds > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Cupón disponible de nuevo"
        content.body = "«\(coupon.title)» ya se puede volver a canjear."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: "cooldown-\(coupon.id)",
                                         content: content, trigger: trigger))
    }
}
