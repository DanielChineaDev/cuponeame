import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

/// Push remota (FCM): registra el dispositivo, guarda el token en
/// `users/{uid}.fcmToken` y presenta las notificaciones. Las Cloud Functions
/// del repo (functions/) usan ese token para avisar de regalos y canjes.
@MainActor
final class PushService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = PushService()

    /// Token pendiente de guardar (llega antes de tener sesión).
    private var pendingToken: String?

    func start() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Si ya hay permiso (p. ej. segunda apertura), registrar sin preguntar.
        Task {
            if await NotificationService.shared.authorizationStatus() == .authorized {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// Llamar tras conceder el permiso de notificaciones.
    func registerForRemote() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// El uid acaba de estar disponible: persistir el token si esperaba.
    func flushPendingToken() {
        guard let token = pendingToken else { return }
        save(token: token)
    }

    private func save(token: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            pendingToken = token
            return
        }
        pendingToken = nil
        Firestore.firestore().collection("users").document(uid)
            .setData(["fcmToken": token], merge: true)
    }

    // MARK: - MessagingDelegate

    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { @MainActor in
            self.save(token: fcmToken)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// En primer plano, banner y sonido (los avisos de regalo ya tienen su
    /// alerta propia dentro de la app; el resto merece verse).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

/// Puente UIKit para el token de APNs (FCM lo necesita).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
