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

    var body: some View {
        TabView(selection: $selectedTab) {
            CouponTabView()
                .environmentObject(authViewModel)

            CreateTabView()

            SettingsTabView()
        }
    }
}
