//
//  CuponesView.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import SwiftUI

struct CouponView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var couponViewModel: CouponViewModel
    
    var body: some View {
        
        NavigationView(){
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(couponViewModel.coupons) { coupon in
                        NavigationLink(destination: CouponDetail(coupon: coupon)) {
                            CardView(coupon: coupon)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Cupones")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    logout
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    username
                }
            }
        }
    }
    
    var logout: some View{
        Button(action: {
            authViewModel.signOut()
            
        }) {
            Text("Cerrar sesión")
        }
    }
    
    var username: some View{
        
        Text(authViewModel.currentUser())
    }
}

//struct CuponesView_Previews: PreviewProvider {
//    static var previews: some View {
//        CouponView()
//            .environmentObject(AuthViewModel())
//    }
//}
