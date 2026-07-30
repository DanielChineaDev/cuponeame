import SwiftUI

/// Conmuta entre bienvenida y la app según la sesión, y engancha el store de
/// cupones al usuario conectado.
struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store

    var body: some View {
        Group {
            if auth.isSignedIn {
                MainTabs()
            } else {
                WelcomeScreen()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isSignedIn)
        .onChange(of: auth.user?.uid, initial: true) { _, uid in
            if let uid {
                store.attach(uid: uid)
            } else if !auth.isDemoMode {
                store.detach()
            }
        }
        .onChange(of: auth.isDemoMode) { _, demo in
            if demo {
                store.attachDemo()
            } else if auth.user == nil {
                store.detach()
            }
        }
    }
}

struct MainTabs: View {
    @Environment(CouponStore.self) private var store

    var body: some View {
        TabView {
            CouponListScreen()
                .tabItem { Label("Cupones", systemImage: "ticket.fill") }

            CreateTab()
                .tabItem { Label("Crear", systemImage: "plus.circle.fill") }

            SettingsScreen()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
        .alert("💝 ¡Regalo de \(store.incomingGift?.from ?? "tu pareja")!",
               isPresented: Binding(
                   get: { store.incomingGift != nil },
                   set: { if !$0 { store.incomingGift = nil } })) {
            Button("Genial") { store.incomingGift = nil }
        } message: {
            Text("Te ha enviado «\(store.incomingGift?.title ?? "un cupón")». Ya está en tu talonario.")
        }
    }
}

/// Pestaña de creación: el formulario en modo "nuevo cupón".
private struct CreateTab: View {
    var body: some View {
        NavigationStack {
            CouponFormScreen(mode: .create)
        }
    }
}
