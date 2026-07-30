import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Sesión de Firebase Auth + perfil (`users/{uid}`). La sesión persiste entre
/// arranques gracias al listener de estado.
@MainActor
@Observable
final class AuthService {
    private(set) var user: FirebaseAuth.User?
    private(set) var userName: String?
    var errorMessage: String?
    var isWorking = false

    private var stateHandle: AuthStateDidChangeListenerHandle?
    private var db: Firestore { Firestore.firestore() }

    var email: String { user?.email ?? "" }

    init() {
        stateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            MainActor.assumeIsolated {
                self?.user = user
                self?.userName = nil
                if user != nil {
                    Task { await self?.loadProfile() }
                }
            }
        }
    }

    // MARK: - Flujos

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

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "No se pudo cerrar la sesión."
        }
    }

    /// Borra los datos de Firestore y después la cuenta de Auth.
    @discardableResult
    func deleteAccount() async -> Bool {
        guard let user else { return false }
        return await run {
            let uid = user.uid
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

    func loadProfile() async {
        guard let uid = user?.uid else { return }
        let document = try? await db.collection("users").document(uid).getDocument()
        userName = document?.data()?["name"] as? String ?? "Sin nombre"
    }

    @discardableResult
    func updateName(_ newName: String) async -> Bool {
        guard let uid = user?.uid, !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return await run {
            try await self.db.collection("users").document(uid)
                .setData(["name": newName], merge: true)
            self.userName = newName
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
