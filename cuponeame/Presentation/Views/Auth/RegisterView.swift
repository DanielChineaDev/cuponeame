//
//  RegisterView.swift
//  cuponeame
//
//  Created by Blue on 18/10/23.
//

import SwiftUI

struct RegisterView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    @Binding var rep_password: String
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack{
             HStack{
                 Text("Nuevo usuario")
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
             
             TextField("Nombre", text: $name)
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
             
             SecureField("Repetir contraseña", text: $rep_password)
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
             
             Spacer()
             
             Button("REGISTRARSE") {
                 authViewModel.signUp(email: email, password: password, name: name)
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
