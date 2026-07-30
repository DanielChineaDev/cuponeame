import SwiftUI

/// Portada de la app: foto + gradiente morado→rosa de la marca, logo y
/// botones de cristal. Es la seña de identidad visual de Cuponéame.
struct WelcomeScreen: View {
    @Environment(AuthService.self) private var auth
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Image("background-home")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.5)

            CuponColors.brandGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)

                Text("Cupones para regalar momentos")
                    .font(.headline.italic())
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Button("INICIAR SESIÓN") { showLogin = true }
                    .buttonStyle(GlassButtonStyle())

                Button("CREAR CUENTA") { showRegister = true }
                    .buttonStyle(GlassButtonStyle())

                Button {
                    auth.enterDemo()
                } label: {
                    Text("Probar sin cuenta")
                        .font(.subheadline.weight(.semibold))
                        .underline()
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 4)

                Text("v\(AppConfig.version) · BPO Studios")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .sheet(isPresented: $showLogin) { LoginSheet() }
        .sheet(isPresented: $showRegister) { RegisterSheet() }
    }
}

#Preview {
    WelcomeScreen()
        .environment(AuthService())
}
