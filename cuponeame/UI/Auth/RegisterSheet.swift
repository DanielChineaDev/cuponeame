import SwiftUI

struct RegisterSheet: View {
    @Environment(AuthService.self) private var auth

    private enum Field { case name, email, password, repeatPassword }

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var repeatPassword = ""
    @State private var showPassword = false
    @State private var validationMessage: String?
    @FocusState private var focus: Field?

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty && !repeatPassword.isEmpty
            && !auth.isWorking
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AuthHeader(
                    title: "Crea tu talonario",
                    subtitle: "Estrenarás \(DefaultCoupons.all.count) cupones listos para regalar 🎁")

                VStack(spacing: 14) {
                    AuthField(icon: "person.fill") {
                        TextField("Nombre", text: $name)
                            .textContentType(.name)
                            .focused($focus, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focus = .email }
                    }

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
                                TextField("Contraseña (mínimo 6)", text: $password)
                            } else {
                                SecureField("Contraseña (mínimo 6)", text: $password)
                            }
                        }
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focus = .repeatPassword }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(CuponColors.subtleText)
                        }
                    }

                    AuthField(icon: "lock.rotation") {
                        SecureField("Repetir contraseña", text: $repeatPassword)
                            .textContentType(.newPassword)
                            .focused($focus, equals: .repeatPassword)
                            .submitLabel(.go)
                            .onSubmit { if canSubmit { submit() } }
                    }

                    if let message = validationMessage ?? auth.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        submit()
                    } label: {
                        if auth.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("CREAR CUENTA")
                        }
                    }
                    .buttonStyle(BrandButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.6)
                    .padding(.top, 6)

                    Text("Al crear la cuenta estrenas el pack de cupones de ejemplo. 💜")
                        .font(.footnote)
                        .foregroundStyle(CuponColors.subtleText)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDragIndicator(.visible)
        .onAppear { auth.errorMessage = nil }
    }

    private func submit() {
        validationMessage = nil
        guard password.count >= 6 else {
            validationMessage = "La contraseña debe tener al menos 6 caracteres."
            return
        }
        guard password == repeatPassword else {
            validationMessage = "Las contraseñas no coinciden."
            return
        }
        Task { await auth.signUp(name: name, email: email, password: password) }
    }
}

#Preview {
    RegisterSheet()
        .environment(AuthService())
}
