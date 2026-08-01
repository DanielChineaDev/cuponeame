import SwiftUI

/// Catálogo de avatares por defecto: imágenes flat de la marca (gradiente +
/// icono) generadas con el mismo lenguaje que el AppIcon. El campo `avatar`
/// de `users/{uid}` guarda el nombre del asset ("avatar_heart"); los valores
/// emoji antiguos se siguen pintando por compatibilidad.
enum Avatars {
    static let all = ["avatar_heart", "avatar_star", "avatar_moon", "avatar_sun",
                      "avatar_leaf", "avatar_paw", "avatar_music", "avatar_game",
                      "avatar_coffee", "avatar_camera", "avatar_plane", "avatar_hare"]
}

/// Círculo de avatar: imagen del set nuevo, emoji legacy o el pingu clásico.
struct AvatarView: View {
    let emoji: String?
    var size: CGFloat = 32

    var body: some View {
        Group {
            if let value = emoji, value.hasPrefix("avatar_") {
                Image(value)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else if let value = emoji, !value.isEmpty {
                // Compatibilidad con perfiles que guardaron un emoji.
                Text(value)
                    .font(.system(size: size * 0.55))
                    .frame(width: size, height: size)
                    .background(
                        LinearGradient(
                            colors: [CuponColors.brandPurple.opacity(0.22),
                                     CuponColors.brandPink.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
            } else {
                Image("pingu-avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            }
        }
        .clipShape(Circle())
    }
}

/// Rejilla para elegir avatar (pingu original + el set de la marca).
struct AvatarPickerSheet: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    option(avatar: nil)
                    ForEach(Avatars.all, id: \.self) { avatar in
                        option(avatar: avatar)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Tu avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func option(avatar: String?) -> some View {
        Button {
            Task {
                await auth.updateAvatar(avatar)
                dismiss()
            }
        } label: {
            AvatarView(emoji: avatar, size: 72)
                .overlay(
                    Circle().stroke(
                        auth.avatar == avatar ? CuponColors.brandPurple : .clear,
                        lineWidth: 3))
        }
        .buttonStyle(.plain)
    }
}
