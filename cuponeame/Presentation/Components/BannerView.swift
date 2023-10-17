//
//  BannerView.swift
//  cuponeame
//
//  Created by Blue on 16/10/23.
//

import SwiftUI

struct BannerView: View {
    var body: some View {
        ZStack {
            Color.white // Color de fondo del banner
            VStack(alignment: .leading) {
                HStack {
                    Text("Título del Banner")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        // Acción para el botón de cerrar
                        print("Cerrar banner")
                    }) {
                        Image(systemName: "xmark")
                            .padding()
                            .foregroundColor(.red)
                    }
                }
                
                Text("Texto debajo del título que puede ser un poco más largo para proporcionar más información sobre el contenido del banner.")
                    .padding([.leading, .trailing])
                    .padding(.top, 10)
                
                Button(action: {
                    // Acción para el botón Más Información
                    print("Más información")
                }) {
                    HStack {
                        Text("Más información")
                        Image(systemName: "chevron.right")
                    }
                    .padding([.leading, .trailing])
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("nombre-de-tu-imagen") // Coloca el nombre de tu imagen aquí
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100) // Tamaño de la imagen
                        .padding()
                }
            }
        }
        .frame(height: 200)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding([.leading, .trailing])
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        BannerView()
    }
}
