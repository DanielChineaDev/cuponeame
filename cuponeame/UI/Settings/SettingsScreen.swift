import SwiftUI

struct SettingsScreen: View {
    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store
    @Environment(MonetizationStore.self) private var monetization

    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue
    @AppStorage("notifsEnabled") private var notifsEnabled = false

    @State private var showNameEditor = false
    @State private var newName = ""
    @State private var showDeleteConfirmation = false
    @State private var showPackConfirmation = false
    @State private var showAvatarPicker = false
    @State private var showPremium = false
    @State private var passwordResetSent = false
    @State private var notifsDenied = false
    @State private var headerCollapse = ScrollCollapse()

    var body: some View {
        NavigationStack {
            BrandHeaderScaffold(collapse: headerCollapse) {
                settingsForm
            } header: { collapse in
                BrandHeader("Ajustes", collapse: collapse)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var settingsForm: some View {
            Form {
                profileCard

                Section {
                    Button {
                        showPremium = true
                    } label: {
                        SettingRow(icon: monetization.isPremium ? "checkmark.seal.fill" : "infinity",
                                   tint: CuponColors.brandPurple,
                                   title: monetization.isPremium ? "Eres premium" : "Cuponéame Premium",
                                   subtitle: monetization.isPremium
                                       ? "Sin anuncios y cupones ilimitados"
                                       : monetization.quotaLabel)
                    }
                } header: {
                    Text("Premium")
                }

                Section("Pareja") {
                    NavigationLink {
                        PartnerScreen()
                    } label: {
                        if let partner = auth.partnerName {
                            SettingRow(icon: "heart.fill", tint: CuponColors.brandPink,
                                       title: "Vinculado con \(partner)")
                        } else {
                            SettingRow(icon: "heart.circle", tint: CuponColors.brandPink,
                                       title: "Modo pareja", subtitle: "Invita a tu persona")
                        }
                    }
                }

                Section {
                    Button {
                        newName = auth.userName ?? ""
                        showNameEditor = true
                    } label: {
                        SettingRow(icon: "person.text.rectangle.fill",
                                   tint: CuponColors.brandPurple, title: "Cambiar nombre")
                    }

                    if !auth.isDemoMode {
                        Button {
                            Task { passwordResetSent = await auth.resetPassword(email: auth.email) }
                        } label: {
                            SettingRow(icon: "key.fill", tint: .orange, title: "Cambiar contraseña")
                        }
                    }
                } header: {
                    Text("Perfil")
                } footer: {
                    if passwordResetSent {
                        Text("Te hemos enviado un correo para cambiar la contraseña.")
                    }
                }

                Section {
                    Toggle(isOn: $notifsEnabled) {
                        SettingRow(icon: "bell.fill", tint: .red,
                                   title: "Avisos",
                                   subtitle: "Regalos y cupones disponibles")
                    }
                    .tint(CuponColors.brandPink)
                } header: {
                    Text("Notificaciones")
                } footer: {
                    if notifsDenied {
                        Text("Permiso denegado. Actívalo en Ajustes de iOS › Cuponéame › Notificaciones.")
                    }
                }

                Section("Actividad") {
                    NavigationLink {
                        HistoryScreen()
                    } label: {
                        SettingRow(icon: "clock.arrow.circlepath", tint: .indigo,
                                   title: "Historial de canjes")
                            .badge(store.redemptions.count)
                    }
                }

                Section {
                    Button {
                        showPackConfirmation = true
                    } label: {
                        SettingRow(icon: "gift.fill", tint: CuponColors.brandPink,
                                   title: "Añadir pack de ejemplo")
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
                        SettingRow(icon: "circle.lefthalf.filled", tint: .gray, title: "Tema")
                    }
                }

                Section("Comparte el amor") {
                    ShareLink(item: "Cuponéame — cupones para regalar momentos a quien más quieres. Hecho por BPO Studios.") {
                        SettingRow(icon: "square.and.arrow.up.fill", tint: CuponColors.brandPurple,
                                   title: "Compartir Cuponéame")
                    }
                    Link(destination: URL(string: "mailto:l3lueart@gmail.com?subject=Sugerencia%20Cupon%C3%A9ame")!) {
                        SettingRow(icon: "envelope.fill", tint: .blue, title: "Enviar una sugerencia")
                    }
                }

                Section("Acerca de") {
                    LabeledContent("Versión", value: AppConfig.version)
                    LabeledContent("Hecho por", value: "BPO Studios")
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
            .brandScrollTracking(headerCollapse)
            .task {
                notifsEnabled = await NotificationService.shared.authorizationStatus() == .authorized
            }
            .onChange(of: notifsEnabled) { _, enabled in
                guard enabled else { notifsDenied = false; return }
                Task {
                    let granted = await NotificationService.shared.requestPermission()
                    notifsEnabled = granted
                    notifsDenied = !granted
                    if granted {
                        PushService.shared.registerForRemote()
                    }
                }
            }
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPickerSheet()
            }
            .fullScreenCover(isPresented: $showPremium) {
                PremiumSheet()
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

    // MARK: - Cabecera y carnet

    /// El carnet es un ticket, como todo en la app: datos arriba, perforación
    /// con muescas y el talón con las estadísticas.
    private static let carnetTopHeight: CGFloat = 108

    private var profileCard: some View {
        Section {
            VStack(spacing: 0) {
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(auth.isDemoMode ? "Modo demo · los cambios no se guardan" : auth.email)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .frame(height: Self.carnetTopHeight)

                HStack(spacing: 0) {
                    stat(value: store.coupons.count, label: "Cupones", icon: "ticket.fill")
                    statDivider
                    stat(value: store.redemptions.count, label: "Canjes", icon: "checkmark.seal.fill")
                    statDivider
                    stat(value: store.coupons.filter(\.favorite).count, label: "Favoritos", icon: "heart.fill")
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
            }
            .background(
                LinearGradient(colors: [CuponColors.brandPurple, CuponColors.brandPink],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(PunchedTicketShape(notchY: Self.carnetTopHeight,
                                          cornerRadius: 24, notchRadius: 10),
                       style: FillStyle(eoFill: true))
            .overlay(TicketPerforation(y: Self.carnetTopHeight, tint: .white.opacity(0.5)))
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

/// Fila de ajustes con icono en cuadradito de color (estilo iOS moderno).
struct SettingRow: View {
    let icon: String
    let tint: Color
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CuponColors.subtleText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        }
    }
}
