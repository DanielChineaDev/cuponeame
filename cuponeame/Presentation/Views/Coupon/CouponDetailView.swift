//
//  CouponDetail.swift
//  cuponeame
//
//  Created by Blue on 26/8/23.
//

import SwiftUI
import Kingfisher

struct CouponDetailView: View {
    @ObservedObject var coupon: CouponModel
    @State private var imageURL: URL?
    
    let randomBar = Int.random(in: 1000000000...9999999999)
    let discount = Int.random(in: 5...90)
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var couponViewModel: CouponViewModel

    @State private var isRedeemConfirmationPresented = false
    @State private var remainingTime: String = "CANJEAR"
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack{
            Spacer()
            
            VStack (alignment: .leading){
                HStack{
                    Text(coupon.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text("\(coupon.redeemCount)/\(coupon.redeemLimit)")
                        .frame(maxWidth: 30)
                }
                
                Text("\(discount)%")
                    .font(.subheadline)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack{
                    Text(coupon.description)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                
                Spacer()
                
                VStack{
                    Image("barcode")
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: 50)
                    
                    Spacer()
                    
                    Text("\(randomBar)")

                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .background(Color(.white))
                .cornerRadius(20)
                .shadow(radius: 5)
                                
            }
            .navigationBarTitle("Detalle de Cupón")
            .onAppear {
                authViewModel.getDownloadableURL(forPath: coupon.imageName) { (url, error) in
                    if let error = error {
                        print("Error obteniendo la URL: \(error.localizedDescription)")
                    } else if let url = url {
                        self.imageURL = url
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                KFImage(imageURL)
                    .resizable()
                    .placeholder {
                        ProgressView().frame(width: 40, height: 40)
                    }
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(20)
                    .clipped()
            )
            .cornerRadius(20)
            
            Spacer()
            
            Button(action: {
                isRedeemConfirmationPresented.toggle()
            }) {
                VStack {
                    if coupon.cooldownExpirationDate ?? Date() > Date() {
                        Text(remainingTime)
                            .font(.headline)
                    } else if coupon.redeemCount == coupon.redeemLimit {
                        Text("SE HA LLEGADO AL LÍMITE DE USOS")
                            .font(.headline)
                    } else {
                        Text("CANJEAR")
                            .font(.headline)
                    }
                    
                    
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(40)
                .opacity((coupon.cooldownExpirationDate ?? Date() > Date() || coupon.redeemCount >= coupon.redeemLimit) ? 0.5 : 1.0)
            }
            .disabled(coupon.cooldownExpirationDate ?? Date() > Date() || coupon.redeemCount >= coupon.redeemLimit)
        }
        .onReceive(timer) { _ in
            updateRemainingTime()
        }
        .onDisappear {
            self.timer.upstream.connect().cancel()
        }
        .padding(12)
        .alert(isPresented: $isRedeemConfirmationPresented) {
            Alert(
                title: Text("Confirmación"),
                message: Text("¿Estás seguro de que deseas canjear este cupón?"),
                primaryButton: .default(
                    Text("Canjear")
                ) {
                    coupon.redeem()
                    if let cooldown = coupon.cooldownTime {
                        coupon.cooldownExpirationDate = Calendar.current.date(byAdding: .second, value: Int(cooldown), to: Date())
                    }
                    authViewModel.couponViewModel.redeemCoupon(couponID: coupon.id, userID: authViewModel.userUID ?? "", cooldownTime: coupon.cooldownTime ?? 86400)
                },
                secondaryButton: .cancel(
                    Text("Cancelar")
                )
            )
        }
    }
    
    func updateRemainingTime() {
        let currentDate = Date()
        guard let expirationDate = coupon.cooldownExpirationDate, expirationDate > currentDate else {
            remainingTime = "CANJEAR"
            coupon.cooldownExpirationDate = nil  // Agrega esta línea para resetear la fecha de expiración
            return
        }

        let interval = expirationDate.timeIntervalSince(currentDate)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60

        remainingTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}


 struct CouponDetailView_Previews: PreviewProvider {
     static var previews: some View {
         CouponDetailView(coupon: CouponModel(
             id: "1",
             title: "Cupón 1",
             category: "Categoría 1",
             description: "Descripción larga del cupón 1.",
             short_description: "Descripción corta 1.",
             imageName: "c1",
             used: false,
             cooldownTime: nil,
             cooldownExpirationDate: nil,
             redeemCount: 0,
             redeemLimit: 5
         ))
     }
 }

