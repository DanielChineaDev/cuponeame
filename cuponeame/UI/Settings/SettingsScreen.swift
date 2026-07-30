import SwiftUI

struct SettingsScreen: View {
    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store

    @State private var showNameEditor = false
    @State private var newName = ""
    @State private var showDeleteConfirmation = false
    @State private var showPackConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                profileHeader

                Section("Perfil") {
                    Button {
                        newName = auth.userName ?? ""
                        showNameEditor = true
                    } label: {
                        Label("Cambiar nombre", systemImage: "pencil")
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

                Section("Acerca de") {
                    LabeledContent("Versión", value: AppConfig.version)
                    LabeledContent("Hecho con 💜 por", value: "BPO Studios")
                }

                Section {
                    Button("Cerrar sesión") {
                        auth.signOut()
                    }

                    Button("Eliminar cuenta", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }

                if let message = auth.errorMessage {
                    Section {
                        Text(message).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Ajustes")
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

    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                Image("pingu-avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(CuponColors.brandStroke, lineWidth: 2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.userName ?? "…")
                        .font(.title3.bold())
                    Text(auth.email)
                        .font(.subheadline)
                        .foregroundStyle(CuponColors.subtleText)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
