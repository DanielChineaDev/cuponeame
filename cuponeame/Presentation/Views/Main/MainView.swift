//
//  MainView.swift
//  cuponeame
//
//  Created by Blue on 6/9/23.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var isProfileSheetPresented = false
    @State private var toolbarImageURL: URL?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                CouponTabView()
                    .environmentObject(authViewModel)
                    .navigationBarTitle("Cupones")
                    .commonToolbar(authViewModel: authViewModel, imageURL: $toolbarImageURL, isProfileSheetPresented: $isProfileSheetPresented)
            }
            .tabItem {
                Image(systemName: "ticket.fill")
                Text("Inicio")
            }
            .tag(0)

            NavigationView {
                CreateTabView()
                    .navigationBarTitle("Crear")
                    .commonToolbar(authViewModel: authViewModel, imageURL: $toolbarImageURL, isProfileSheetPresented: $isProfileSheetPresented)
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Crear")
            }
            .tag(1)

            NavigationView {
                SettingsTabView()
                    .navigationBarTitle("Ajustes")
                    .commonToolbar(authViewModel: authViewModel, imageURL: $toolbarImageURL, isProfileSheetPresented: $isProfileSheetPresented)
            }
            .tabItem {
                Image(systemName: "gearshape.circle.fill")
                Text("Ajustes")
            }
            .tag(2)
        }
    }
}
