//
//  LoginView.swift
//  cuponeame
//
//  Created by Blue on 31/8/23.
//

import SwiftUI

struct LoginView: View {
    @Binding var email: String
    @Binding var password: String
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack{
            HStack{
                Text("Iniciar sesión")
                    .font(.system(size: 32)) // Tamaño de fuente personalizado
                    .fontWeight(.heavy)
                    .foregroundColor(Color(.black))
                Spacer()
            }

            Spacer()
            
            
            Image("placeholder")
                .resizable()
                .frame(maxWidth: 150, maxHeight: 150)
                .aspectRatio(contentMode: .fit)
            
            Spacer()
            
            TextField("Correo electrónico", text: $email)
                .padding(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            , lineWidth: 2)
                )
            
            SecureField("Contraseña", text: $password)
                .padding(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            , lineWidth: 2)
                )

            HStack{
                Spacer()
                Text("He olvidado mi contraseña")
                    .foregroundColor(Color.gray)
            }
            
            
            Spacer()
            
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
        }
        .padding(20)
    }
}
