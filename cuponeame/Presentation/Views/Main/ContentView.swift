//
//  ContentView.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var name: String = "Daniel"
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
                Image("background-home")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.5)
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    
                    Spacer()
                    
                    Button("INICIAR SESIÓN", action: {
                        isLoginSheetPresented.toggle()
                    })
                    .buttonStyle(BlurButtonStyle())
                    
                    Button("REGISTRARSE", action: {
                        isRegisterSheetPresented.toggle()
                    })
                    .buttonStyle(BlurButtonStyle())
                    
                    Text("v1407.23 2023")
                        .font(.footnote)
                    
                    .sheet(isPresented: $isLoginSheetPresented) {
                        LoginView(email: $email, password: $password)
                            .environmentObject(authViewModel)
                    }
                    
                    .sheet(isPresented: $isRegisterSheetPresented) {
                        RegisterView(name: $name, email: $email, password: $password, rep_password: $rep_password)
                            .environmentObject(authViewModel)
                    }
                }
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}

