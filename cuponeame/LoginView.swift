//
//  LoginView.swift
//  cuponeame
//
//  Created by Blue on 31/8/23.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            Spacer()
            TextField("Correo electrónico", text: $email)
                .padding()
            SecureField("Contraseña", text: $password)
                .padding()

            Button("INICIAR SESIÓN") {
                authViewModel.signIn(email: email, password: password)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(40)

            Button("REGISTRARSE") {
                //authViewModel.signUp(email: email, password: password)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(40)
            
            Spacer()
            
        }
        .padding(20)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
