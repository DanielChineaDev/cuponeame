//
//  ProfileView.swift
//  cuponeame
//
//  Created by Blue on 2/11/23.
//

import SwiftUI
import FirebaseStorage
import Kingfisher

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var imageURL: URL?
    @Binding var isProfileSheetPresented: Bool

    var body: some View {
            VStack(alignment: .leading) {
                Spacer()
                    VStack {
                        KFImage(imageURL)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 0)
                            )
                        
                        Text("Nombre: " + (authViewModel.userName ?? ""))
                        Text("Email: " + (authViewModel.user?.email ?? ""))

                    }
                Spacer()
                Button(action: {
                    authViewModel.signOut()
                    isProfileSheetPresented.toggle()
                }) {
                    Text("Cerrar sesión")
                }
                .buttonStyle(BlurRedButtonStyle())

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }


//struct Content: View {
//    var body: some View {
//        CardView(title: "Ir a tomer cervecita", category: "Gastronomía", short_description: "Esto es una descripcion corta de lo que podria ser un real.", imageName: "cerveza-cupon")
//    }
//}
//
//struct Content_Previews: PreviewProvider {
//    static var previews: some View {
//        Content()
//    }
//}

