import SwiftUI

/// Conmuta entre bienvenida y la app según la sesión, y engancha el store de
/// cupones al usuario conectado.
struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store

    var body: some View {
        Group {
            if auth.user != nil {
                MainTabs()
            } else {
                WelcomeScreen()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.user?.uid)
        .onChange(of: auth.user?.uid, initial: true) { _, uid in
            if let uid {
                store.attach(uid: uid)
            } else {
                store.detach()
            }
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            CouponListScreen()
                .tabItem { Label("Cupones", systemImage: "ticket.fill") }

            CreateTab()
                .tabItem { Label("Crear", systemImage: "plus.circle.fill") }

            SettingsScreen()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
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
