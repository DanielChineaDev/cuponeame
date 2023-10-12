//
//  MainView.swift
//  cuponeame
//
//  Created by Blue on 6/9/23.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0 // Variable para controlar la pestaña seleccionada
    @EnvironmentObject var authViewModel: AuthViewModel


    var body: some View {
        TabView(selection: $selectedTab) { // TabView con selección
            // Primera pestaña
            CouponView(authViewModel: authViewModel, couponViewModel: authViewModel.couponViewModel)
                .environmentObject(authViewModel.couponViewModel)
                .tabItem {
                    Image(systemName: "ticket.fill") // Icono de la pestaña 1
                    Text("Inicio")
                }
                .tag(0) // Etiqueta para la selección
            
            // Segunda pestaña
            Text("Pestaña 2")
                .tabItem {
                    Image(systemName: "plus.circle.fill") // Icono de la pestaña 2
                    Text("Crear")
                }
                .tag(1) // Etiqueta para la selección
            
            // Tercera pestaña
            Text("Pestaña 3")
                .tabItem {
                    Image(systemName: "gearshape.circle.fill") // Icono de la pestaña 3
                    Text("Ajustes")
                }
                .tag(2) // Etiqueta para la selección
        }
    }
}
