import SwiftUI

/// Portada de la app: gradiente morado→rosa con corazones flotando, el
/// ticket de la marca y botones de cristal. La seña de identidad visual.
struct WelcomeScreen: View {
    @Environment(AuthService.self) private var auth
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            background

            FloatingShapes()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                BrandMark(width: 230)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                BrandWordmark(size: 46)
                    .padding(.top, 28)

                Text("Cupones para regalar momentos")
                    .font(.headline.italic())
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                Group {
                    Button("EMPEZAR") { showRegister = true }
                        .buttonStyle(GlassButtonStyle())

                    Button("YA TENGO CUENTA") { showLogin = true }
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
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

                Text("v\(AppConfig.version) · BPO Studios")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.35)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showLogin) { LoginSheet() }
        .sheet(isPresented: $showRegister) { RegisterSheet() }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [CuponColors.brandPurple, CuponColors.brandPink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Blobs suaves, como en el AppIcon.
            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 420, height: 420)
                .offset(x: -160, y: -300)
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 380, height: 380)
                .offset(x: 180, y: 320)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    WelcomeScreen()
        .environment(AuthService())
}
