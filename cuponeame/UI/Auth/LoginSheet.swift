import SwiftUI

struct LoginSheet: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    private enum Field { case email, password }

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showReset = false
    @State private var resetEmail = ""
    @State private var resetSent = false
    @FocusState private var focus: Field?

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !auth.isWorking
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AuthHeader(
                    title: "¡Hola de nuevo!",
                    subtitle: "Tus cupones te estaban esperando 💜")

                VStack(spacing: 14) {
                    AuthField(icon: "envelope.fill") {
                        TextField("Correo electrónico", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focus, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focus = .password }
                    }

                    AuthField(icon: "lock.fill") {
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
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { if canSubmit { submit() } }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(CuponColors.subtleText)
                        }
                    }

                    HStack {
                        Spacer()
                        Button("He olvidado mi contraseña") {
                            resetEmail = email
                            showReset = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(CuponColors.brandPurple)
                    }

                    if let message = auth.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if resetSent {
                        Label("Te hemos enviado un correo para restablecerla.",
                              systemImage: "envelope.badge.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        submit()
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
                    .padding(.top, 6)
                }
                .padding(20)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
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

    private func submit() {
        Task { await auth.signIn(email: email, password: password) }
    }
}

#Preview {
    LoginSheet()
        .environment(AuthService())
}
