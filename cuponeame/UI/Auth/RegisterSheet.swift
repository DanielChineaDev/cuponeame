import SwiftUI

struct RegisterSheet: View {
    @Environment(AuthService.self) private var auth

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var repeatPassword = ""
    @State private var validationMessage: String?

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty && !repeatPassword.isEmpty
            && !auth.isWorking
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Nuevo usuario")
                    .font(.system(size: 32, weight: .heavy))
                Spacer()
            }

            Spacer()

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 120)

            Spacer()

            TextField("Nombre", text: $name)
                .textContentType(.name)
                .brandField()

            TextField("Correo electrónico", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .brandField()

            SecureField("Contraseña", text: $password)
                .textContentType(.newPassword)
                .brandField()

            SecureField("Repetir contraseña", text: $repeatPassword)
                .textContentType(.newPassword)
                .brandField()

            if let message = validationMessage ?? auth.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            Button {
                submit()
            } label: {
                if auth.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text("REGISTRARSE")
                }
            }
            .buttonStyle(BrandButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.6)
        }
        .padding(20)
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
