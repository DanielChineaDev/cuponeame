import SwiftUI

/// Catálogo de avatares emoji seleccionables (campo `avatar` en `users/{uid}`).
enum Avatars {
    static let all = ["🐧", "🦊", "🐻", "🐰", "🐱", "🐶", "🐼", "🦁", "🐨", "🦄",
                      "🐸", "🐙", "🌻", "🌙", "⭐️", "🌈", "🍓", "🍕", "☕️", "🎸"]
}

/// Círculo de avatar: el emoji elegido sobre gradiente suave de marca, o el
/// pingu clásico si no se ha elegido ninguno.
struct AvatarView: View {
    let emoji: String?
    var size: CGFloat = 32

    var body: some View {
        Group {
            if let emoji, !emoji.isEmpty {
                Text(emoji)
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

/// Rejilla para elegir avatar (pingu original + emojis).
struct AvatarPickerSheet: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    option(emoji: nil)
                    ForEach(Avatars.all, id: \.self) { emoji in
                        option(emoji: emoji)
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

    private func option(emoji: String?) -> some View {
        Button {
            Task {
                await auth.updateAvatar(emoji)
                dismiss()
            }
        } label: {
            AvatarView(emoji: emoji, size: 56)
                .overlay(
                    Circle().stroke(
                        auth.avatar == emoji ? CuponColors.brandPurple : .clear,
                        lineWidth: 3))
        }
        .buttonStyle(.plain)
    }
}
