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
    
    @State private var imageURL: URL?
    
    var body: some View {
        
        NavigationView(){
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
            .navigationBarTitle("Cupones")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    logout
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Genial funciona")
                        
                    }) {
                        userDisplay
                    }
                    
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
        authViewModel.currentUserName()
        return Text(authViewModel.userName ?? "")
    }
    
    var userDisplay: some View {
        HStack(spacing: 8) {
            username
            CircularImageView(imageURL: self.imageURL)
        }
        .onAppear {
            authViewModel.getDownloadableURL(forPath: "/defaults-avatars/pingu-avatar.jpg") { (url, error) in
                if let error = error {
                    print("Error obteniendo la URL: \(error.localizedDescription)")
                } else if let url = url {
                    self.imageURL = url
                }
            }
        }
    }
    
    struct CircularImageView: View {
        var imageURL: URL?
        
        var body: some View {
            //Aqui se implementara la carga de la imagen desde firebase
            KFImage(imageURL)
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 0)
                )
        }
    }
    
}

struct CouponListView_Previews: PreviewProvider {
    static var previews: some View {
        CouponListView(authViewModel: AuthViewModel(), couponViewModel: CouponViewModel())
            .environmentObject(AuthViewModel())
    }
}
