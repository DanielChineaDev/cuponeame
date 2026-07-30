import SwiftUI

struct SettingsScreen: View {
    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store

    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    @State private var showNameEditor = false
    @State private var newName = ""
    @State private var showDeleteConfirmation = false
    @State private var showPackConfirmation = false
    @State private var showAvatarPicker = false
    @State private var passwordResetSent = false

    var body: some View {
        NavigationStack {
            Form {
                profileCard

                Section("Pareja") {
                    NavigationLink {
                        PartnerScreen()
                    } label: {
                        if let partner = auth.partnerName {
                            Label("Vinculado con \(partner)", systemImage: "heart.circle.fill")
                                .foregroundStyle(CuponColors.brandPink)
                        } else {
                            Label("Modo pareja · invita a tu persona", systemImage: "heart.circle")
                        }
                    }
                }

                Section {
                    Button {
                        newName = auth.userName ?? ""
                        showNameEditor = true
                    } label: {
                        Label("Cambiar nombre", systemImage: "pencil")
                    }

                    if !auth.isDemoMode {
                        Button {
                            Task { passwordResetSent = await auth.resetPassword(email: auth.email) }
                        } label: {
                            Label("Cambiar contraseña", systemImage: "key.fill")
                        }
                    }
                } header: {
                    Text("Perfil")
                } footer: {
                    if passwordResetSent {
                        Text("Te hemos enviado un correo para cambiar la contraseña. ✉️")
                    }
                }

                Section("Actividad") {
                    NavigationLink {
                        HistoryScreen()
                    } label: {
                        Label("Historial de canjes", systemImage: "clock.arrow.circlepath")
                            .badge(store.redemptions.count)
                    }
                }

                Section {
                    Button {
                        showPackConfirmation = true
                    } label: {
                        Label("Añadir pack de ejemplo", systemImage: "gift.fill")
                    }
                } header: {
                    Text("Cupones")
                } footer: {
                    Text("Añade de nuevo los \(DefaultCoupons.all.count) cupones con los que estrena la app.")
                }

                Section("Apariencia") {
                    Picker(selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme.rawValue)
                        }
                    } label: {
                        Label("Tema", systemImage: "circle.lefthalf.filled")
                    }
                }

                Section("Comparte el amor") {
                    ShareLink(item: "🎟️ Cuponéame — cupones para regalar momentos a quien más quieres. Hecho con 💜 por BPO Studios.") {
                        Label("Compartir Cuponéame", systemImage: "square.and.arrow.up")
                    }
                    Link(destination: URL(string: "mailto:l3lueart@gmail.com?subject=Sugerencia%20Cupon%C3%A9ame")!) {
                        Label("Enviar una sugerencia", systemImage: "envelope.fill")
                    }
                }

                Section("Acerca de") {
                    LabeledContent("Versión", value: AppConfig.version)
                    LabeledContent("Hecho con 💜 por", value: "BPO Studios")
                }

                Section {
                    Button(auth.isDemoMode ? "Salir del modo demo" : "Cerrar sesión") {
                        auth.signOut()
                    }

                    if !auth.isDemoMode {
                        Button("Eliminar cuenta", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    }
                }

                if let message = auth.errorMessage {
                    Section {
                        Text(message).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Ajustes")
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPickerSheet()
            }
            .alert("Cambiar nombre", isPresented: $showNameEditor) {
                TextField("Nombre", text: $newName)
                Button("Guardar") {
                    Task { await auth.updateName(newName) }
                }
                Button("Cancelar", role: .cancel) {}
            }
            .alert("¿Añadir el pack de ejemplo?", isPresented: $showPackConfirmation) {
                Button("Añadir") {
                    Task { await store.addDefaultPack() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se añadirán \(DefaultCoupons.all.count) cupones a tu lista. Los que ya tienes no se tocan.")
            }
            .alert("¿Eliminar tu cuenta?", isPresented: $showDeleteConfirmation) {
                Button("Eliminar todo", role: .destructive) {
                    Task { await auth.deleteAccount() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se borrarán tus cupones, tu historial y tu cuenta. Esta acción no se puede deshacer.")
            }
        }
    }

    // MARK: - Carnet de perfil

    private var profileCard: some View {
        Section {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button {
                        showAvatarPicker = true
                    } label: {
                        AvatarView(emoji: auth.avatar, size: 72)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(CuponColors.brandPurple, .white)
                            }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(auth.userName ?? "…")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(auth.isDemoMode ? "Modo demo · los cambios no se guardan" : auth.email)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                }

                HStack(spacing: 0) {
                    stat(value: store.coupons.count, label: "Cupones", icon: "ticket.fill")
                    statDivider
                    stat(value: store.redemptions.count, label: "Canjes", icon: "checkmark.seal.fill")
                    statDivider
                    stat(value: store.coupons.filter(\.favorite).count, label: "Favoritos", icon: "heart.fill")
                }
                .padding(.vertical, 10)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(18)
            .background(
                LinearGradient(colors: [CuponColors.brandPurple, CuponColors.brandPink],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24))
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private var statDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.3))
            .frame(width: 1, height: 36)
    }

    private func stat(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
            Text("\(value)")
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }
}
