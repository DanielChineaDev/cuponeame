import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Errores propios del modo pareja, con mensaje en español.
enum PartnerError: Error {
    case codeNotFound
    case ownCode

    var message: String {
        switch self {
        case .codeNotFound: "Ese código no existe o ya se ha usado."
        case .ownCode: "Ese código es tuyo: pásaselo a tu pareja 😉"
        }
    }
}

/// Sesión de Firebase Auth + perfil (`users/{uid}`) con listener en vivo:
/// nombre y vínculo de pareja se refrescan solos (p. ej. cuando tu pareja
/// canjea tu código de invitación desde su móvil).
@MainActor
@Observable
final class AuthService {
    private(set) var user: FirebaseAuth.User?
    private(set) var userName: String?
    /// Emoji de avatar elegido; nil = pingu clásico.
    private(set) var avatar: String?
    /// Modo pareja: uid y nombre de la persona vinculada.
    private(set) var partnerUID: String?
    private(set) var partnerName: String?
    /// Modo demo: la app entera funciona con datos locales, sin cuenta.
    private(set) var isDemoMode = false
    var errorMessage: String?
    var isWorking = false

    private var stateHandle: AuthStateDidChangeListenerHandle?
    private var profileListener: ListenerRegistration?
    private var db: Firestore { Firestore.firestore() }

    var email: String { user?.email ?? "" }

    /// Hay sesión real o modo demo: se muestra la app interior.
    var isSignedIn: Bool { user != nil || isDemoMode }

    init() {
        stateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.user = user
                self.userName = nil
                self.avatar = nil
                self.partnerUID = nil
                self.partnerName = nil
                self.profileListener?.remove()
                self.profileListener = nil
                if let user {
                    self.observeProfile(uid: user.uid)
                }
            }
        }
    }

    private func observeProfile(uid: String) {
        profileListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                MainActor.assumeIsolated {
                    guard let self, let data = snapshot?.data() else { return }
                    self.userName = data["name"] as? String ?? "Sin nombre"
                    self.avatar = data["avatar"] as? String
                    self.partnerUID = data["partnerUID"] as? String
                    self.partnerName = data["partnerName"] as? String
                }
            }
    }

    // MARK: - Flujos de sesión

    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        await run {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        }
    }

    @discardableResult
    func signUp(name: String, email: String, password: String) async -> Bool {
        await run {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            try await self.db.collection("users").document(uid).setData([
                "name": name,
                "email": email,
            ])
            // Toda cuenta nueva estrena el pack de cupones de ejemplo.
            try await CouponStore.seedDefaults(uid: uid)
            self.userName = name
        }
    }

    @discardableResult
    func resetPassword(email: String) async -> Bool {
        await run {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        }
    }

    func enterDemo() {
        isDemoMode = true
        userName = "Invitado"
        avatar = nil
        partnerUID = nil
        partnerName = nil
    }

    func signOut() {
        if isDemoMode {
            isDemoMode = false
            userName = nil
            avatar = nil
            partnerUID = nil
            partnerName = nil
            return
        }
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "No se pudo cerrar la sesión."
        }
    }

    /// Borra los datos de Firestore y después la cuenta de Auth.
    @discardableResult
    func deleteAccount() async -> Bool {
        guard let user, !isDemoMode else { return false }
        return await run {
            let uid = user.uid
            if let partnerUID = self.partnerUID {
                try? await self.db.collection("users").document(partnerUID).updateData(
                    ["partnerUID": FieldValue.delete(), "partnerName": FieldValue.delete()])
            }
            let userRef = self.db.collection("users").document(uid)
            for collection in ["coupons", "redemptions"] {
                let snapshot = try await userRef.collection(collection).getDocuments()
                for document in snapshot.documents {
                    try await document.reference.delete()
                }
            }
            try await userRef.delete()
            try await user.delete()
        }
    }

    // MARK: - Perfil

    @discardableResult
    func updateName(_ newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        if isDemoMode {
            userName = trimmed
            return true
        }
        guard let uid = user?.uid else { return false }
        return await run {
            try await self.db.collection("users").document(uid)
                .setData(["name": trimmed], merge: true)
        }
    }

    /// Cambia el avatar (emoji) o vuelve al pingu clásico con nil.
    @discardableResult
    func updateAvatar(_ emoji: String?) async -> Bool {
        if isDemoMode {
            avatar = emoji
            return true
        }
        guard let uid = user?.uid else { return false }
        return await run {
            try await self.db.collection("users").document(uid)
                .setData(["avatar": emoji ?? FieldValue.delete()], merge: true)
        }
    }

    // MARK: - Modo pareja

    /// Crea un código de invitación (`invites/{code}`) y lo devuelve.
    func createInviteCode() async -> String? {
        if isDemoMode { return "AMAR26" }
        guard let user else { return nil }
        let code = InviteCode.generate()
        let success = await run {
            try await self.db.collection("invites").document(code).setData([
                "ownerUID": user.uid,
                "ownerName": self.userName ?? "Alguien que te quiere",
                "createdAt": Timestamp(date: Date()),
            ])
        }
        return success ? code : nil
    }

    /// Canjea el código de la pareja: vincula ambas cuentas y consume el código.
    @discardableResult
    func redeemInviteCode(_ rawCode: String) async -> Bool {
        let code = InviteCode.normalized(rawCode)
        if isDemoMode {
            errorMessage = nil
            guard !code.isEmpty else {
                errorMessage = PartnerError.codeNotFound.message
                return false
            }
            partnerUID = "demo-pareja"
            partnerName = "Pao"
            return true
        }
        guard let user, InviteCode.isValid(code) else {
            errorMessage = PartnerError.codeNotFound.message
            return false
        }
        return await run {
            let snapshot = try await self.db.collection("invites").document(code).getDocument()
            guard let data = snapshot.data(),
                  let ownerUID = data["ownerUID"] as? String else {
                throw PartnerError.codeNotFound
            }
            guard ownerUID != user.uid else { throw PartnerError.ownCode }

            let ownerName = data["ownerName"] as? String ?? "Tu pareja"
            let myName = self.userName ?? "Tu pareja"
            let users = self.db.collection("users")
            let batch = self.db.batch()
            batch.setData(["partnerUID": ownerUID, "partnerName": ownerName],
                          forDocument: users.document(user.uid), merge: true)
            batch.setData(["partnerUID": user.uid, "partnerName": myName],
                          forDocument: users.document(ownerUID), merge: true)
            batch.deleteDocument(snapshot.reference)
            try await batch.commit()
        }
    }

    /// Avatar de la pareja, leído de su perfil; nil = pingu clásico.
    func fetchPartnerAvatar() async -> String? {
        if isDemoMode {
            return partnerUID == nil ? nil : "avatar_hare"
        }
        guard let partnerUID else { return nil }
        let document = try? await db.collection("users").document(partnerUID).getDocument()
        return document?.data()?["avatar"] as? String
    }

    /// Rompe el vínculo en ambas cuentas.
    func unlinkPartner() async {
        if isDemoMode {
            partnerUID = nil
            partnerName = nil
            return
        }
        guard let user, let partnerUID else { return }
        _ = await run {
            let users = self.db.collection("users")
            let clear: [String: Any] = [
                "partnerUID": FieldValue.delete(),
                "partnerName": FieldValue.delete(),
            ]
            let batch = self.db.batch()
            batch.updateData(clear, forDocument: users.document(user.uid))
            batch.updateData(clear, forDocument: users.document(partnerUID))
            try await batch.commit()
        }
    }

    // MARK: - Errores

    /// Ejecuta un flujo marcando `isWorking` y traduciendo el error a español.
    private func run(_ body: @escaping () async throws -> Void) async -> Bool {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await body()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    static func message(for error: Error) -> String {
        if let partnerError = error as? PartnerError {
            return partnerError.message
        }
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .invalidEmail: return "El correo no tiene un formato válido."
        case .wrongPassword, .invalidCredential: return "Correo o contraseña incorrectos."
        case .userNotFound: return "No existe ninguna cuenta con ese correo."
        case .emailAlreadyInUse: return "Ya existe una cuenta con ese correo."
        case .weakPassword: return "La contraseña debe tener al menos 6 caracteres."
        case .networkError: return "Sin conexión. Inténtalo de nuevo."
        case .tooManyRequests: return "Demasiados intentos. Espera un momento."
        case .requiresRecentLogin: return "Por seguridad, cierra sesión y vuelve a entrar antes de repetir esta acción."
        default: return "Algo salió mal. Inténtalo de nuevo."
        }
    }
}
