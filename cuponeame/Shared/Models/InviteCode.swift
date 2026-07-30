import Foundation

/// Códigos de invitación del modo pareja (`invites/{code}` en Firestore).
/// Alfabeto sin caracteres ambiguos (sin 0/O ni 1/I) para poder dictarlos.
enum InviteCode {
    static let length = 6
    static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func generate() -> String {
        String((0..<length).map { _ in alphabet.randomElement()! })
    }

    /// Limpia lo que escriba el usuario: mayúsculas y solo caracteres válidos.
    static func normalized(_ raw: String) -> String {
        String(raw.uppercased().filter { alphabet.contains($0) }.prefix(length))
    }

    static func isValid(_ code: String) -> Bool {
        code.count == length && code.allSatisfy { alphabet.contains($0) }
    }
}
