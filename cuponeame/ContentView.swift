//
//  ContentView.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @State private var name: String = ""
    @State private var email: String = "l3lueart@gmail.com"
    @State private var password: String = "u_38002508"
    @State private var rep_password: String = ""

    @State private var isPasswordVisible = false
    @State private var isLoginSheetPresented = false
    @State private var isRegisterSheetPresented = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    
    var body: some View {
        NavigationView {
            ZStack{
                Image("background_home")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack{
                    Spacer()
                    Text("CUPONEAME")
                        .font(.system(size: 48)) // Tamaño de fuente personalizado
                        .fontWeight(.heavy)
                        .foregroundColor(Color(.white))
                    
                    Text("Hecha para la princesa más bella del mundo")
                        .foregroundColor(Color(.white))
                    
                    Spacer()
                    
                    VStack{
                        
                        Spacer()
                        
                        Button("INICIAR SESIÓN") {
                            isLoginSheetPresented.toggle()
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
                            isRegisterSheetPresented.toggle()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(40)
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
                        
                        Text("Ver. 1407.23 2023")
                            .font(.system(size: 8)) // Tamaño de fuente personalizado
                            .foregroundColor(.black)
                        
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: 250)
                    .background(Color(.white))
                    .cornerRadius(40)
                }
                .sheet(isPresented: $isLoginSheetPresented) {
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
                
                .sheet(isPresented: $isRegisterSheetPresented) {
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
                .ignoresSafeArea()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
