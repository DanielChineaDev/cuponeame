import SwiftUI

/// Perfil del usuario (se abre tocando el avatar en Cupones): avatar grande,
/// datos de la cuenta, resumen y con quién está vinculado en modo pareja.
struct ProfileSheet: View {
    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showAvatarPicker = false
    @State private var partnerAvatar: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    identity

                    summary

                    partnerCard
                }
                .padding(16)
            }
            .background(CuponColors.background)
            .navigationTitle("Tu perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPickerSheet()
            }
            .task(id: auth.partnerUID) {
                partnerAvatar = await auth.fetchPartnerAvatar()
            }
        }
    }

    // MARK: - Identidad

    private var identity: some View {
        VStack(spacing: 12) {
            Button {
                showAvatarPicker = true
            } label: {
                AvatarView(emoji: auth.avatar, size: 96)
                    .overlay(Circle().stroke(CuponColors.brandStroke, lineWidth: 3))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white, CuponColors.brandPurple)
                    }
            }
            .buttonStyle(.plain)

            VStack(spacing: 3) {
                Text(auth.userName ?? "…")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                Text(auth.isDemoMode ? "Modo demo · los cambios no se guardan" : auth.email)
                    .font(.subheadline)
                    .foregroundStyle(CuponColors.subtleText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var summary: some View {
        HStack(spacing: 0) {
            stat(value: store.coupons.count, label: "Cupones", icon: "ticket.fill")
            divider
            stat(value: store.redemptions.count, label: "Canjes", icon: "checkmark.seal.fill")
            divider
            stat(value: store.coupons.filter(\.favorite).count, label: "Favoritos", icon: "heart.fill")
        }
        .padding(.vertical, 12)
        .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(CuponColors.brandPurple.opacity(0.1), lineWidth: 1))
    }

    private var divider: some View {
        Rectangle()
            .fill(CuponColors.subtleText.opacity(0.2))
            .frame(width: 1, height: 36)
    }

    private func stat(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(CuponColors.brandPink)
            Text("\(value)")
                .font(.title3.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(CuponColors.subtleText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pareja

    @ViewBuilder
    private var partnerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PAREJA")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CuponColors.subtleText)
                .padding(.leading, 6)

            VStack(spacing: 14) {
                if let partner = auth.partnerName {
                    HStack(spacing: 18) {
                        avatarWithName(emoji: auth.avatar, name: auth.userName ?? "Tú")

                        Image(systemName: "heart.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(CuponColors.brandStroke)

                        avatarWithName(emoji: partnerAvatar, name: partner)
                    }
                    .frame(maxWidth: .infinity)

                    Text("Conectado con **\(partner)**: os podéis regalar cupones el uno al otro.")
                        .font(.subheadline)
                        .foregroundStyle(CuponColors.subtleText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    NavigationLink {
                        PartnerScreen()
                    } label: {
                        Label("Gestionar vínculo", systemImage: "heart.text.square.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 30))
                        .foregroundStyle(CuponColors.subtleText)

                    Text("Todavía no estás vinculado con nadie.")
                        .font(.subheadline)
                        .foregroundStyle(CuponColors.subtleText)

                    NavigationLink {
                        PartnerScreen()
                    } label: {
                        Text("VINCULAR CON TU PAREJA")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(CuponColors.brandStroke, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(CuponColors.brandPurple.opacity(0.1), lineWidth: 1))
        }
    }

    private func avatarWithName(emoji: String?, name: String) -> some View {
        VStack(spacing: 6) {
            AvatarView(emoji: emoji, size: 64)
                .overlay(Circle().stroke(CuponColors.brandStroke, lineWidth: 2))
            Text(name)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
        }
        .frame(width: 92)
    }
}
