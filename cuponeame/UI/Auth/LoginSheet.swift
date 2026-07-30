import SwiftUI

struct LoginSheet: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showReset = false
    @State private var resetEmail = ""
    @State private var resetSent = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !auth.isWorking
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Iniciar sesión")
                    .font(.system(size: 32, weight: .heavy))
                Spacer()
            }

            Spacer()

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 140)

            Spacer()

            TextField("Correo electrónico", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .brandField()

            passwordField

            HStack {
                Spacer()
                Button("He olvidado mi contraseña") {
                    resetEmail = email
                    showReset = true
                }
                .font(.subheadline)
                .foregroundStyle(CuponColors.subtleText)
            }

            if let message = auth.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if resetSent {
                Text("Te hemos enviado un correo para restablecer la contraseña.")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            Button {
                Task { await auth.signIn(email: email, password: password) }
            } label: {
                if auth.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text("INICIAR SESIÓN")
                }
            }
            .buttonStyle(BrandButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.6)
        }
        .padding(20)
        .presentationDragIndicator(.visible)
        .onAppear { auth.errorMessage = nil }
        .alert("Recuperar contraseña", isPresented: $showReset) {
            TextField("Correo electrónico", text: $resetEmail)
                .textInputAutocapitalization(.never)
            Button("Enviar") {
                Task { resetSent = await auth.resetPassword(email: resetEmail) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Te enviaremos un enlace para restablecerla.")
        }
    }

    private var passwordField: some View {
        HStack {
            Group {
                if showPassword {
                    TextField("Contraseña", text: $password)
                } else {
                    SecureField("Contraseña", text: $password)
                }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(CuponColors.subtleText)
            }
        }
        .brandField()
    }
}

#Preview {
    LoginSheet()
        .environment(AuthService())
}
