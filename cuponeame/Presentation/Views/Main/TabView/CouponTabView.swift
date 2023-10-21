//
//  CouponTabView.swift
//  cuponeame
//
//  Created by Blue on 18/10/23.
//

import SwiftUI

struct CouponTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        CouponListView(authViewModel: authViewModel, couponViewModel: authViewModel.couponViewModel)
            .environmentObject(authViewModel.couponViewModel)
            .tabItem {
                Image(systemName: "ticket.fill")
                Text("Inicio")
            }
            .tag(0)
    }
}
