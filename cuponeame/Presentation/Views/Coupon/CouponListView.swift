//
//  CuponesView.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import SwiftUI
import Kingfisher

struct CouponListView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var couponViewModel: CouponViewModel
        
    var body: some View {
        
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(couponViewModel.coupons) { coupon in
                        NavigationLink(destination: CouponDetailView(coupon: coupon)) {
                            CouponView(coupon: coupon, authVM: authViewModel)
                        }
                    }
                }
                .padding()
        }
    }
}

struct CouponListView_Previews: PreviewProvider {
    static var previews: some View {
        CouponListView(authViewModel: AuthViewModel(), couponViewModel: CouponViewModel())
            .environmentObject(AuthViewModel())
    }
}
