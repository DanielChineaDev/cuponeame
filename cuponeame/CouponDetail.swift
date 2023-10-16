//
//  CouponDetail.swift
//  cuponeame
//
//  Created by Blue on 26/8/23.
//

import SwiftUI

struct CouponDetail: View {
    @ObservedObject var coupon: Coupon
    
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
                Text(coupon.title)
                    .font(.system(size: 48)) // Tamaño de fuente personalizado
                    .fontWeight(.heavy)
                
                Text("\(discount)%")
                    .font(.system(size: 16)) // Tamaño de fuente personalizado
                    .fontWeight(.light)
                
                Spacer()
                
                HStack{
                    Text(coupon.description)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                
                Spacer()
                
            }
            .navigationBarTitle("Detalle de Cupón")
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: 400)
            .background(
                Image("c1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
            .foregroundColor(.white)
            .cornerRadius(40)
            .shadow(radius: 5)
            
            VStack{
                Image("barcode")
                    .resizable()
                //.aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 50)
                
                Text("\(randomBar)")
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: 100)
            .background(Color(.white))
            .cornerRadius(40)
            .shadow(radius: 5)
            
            Spacer()
            
            Text("Canjeado: \(coupon.redeemCount) de \(coupon.redeemLimit)")
            
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


 struct CouponDetail_Previews: PreviewProvider {
     static var previews: some View {
         CouponDetail(coupon: Coupon(
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

