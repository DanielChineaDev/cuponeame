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
            
            Button(action: {
                isRedeemConfirmationPresented.toggle()
            }) {
                Text("CANJEAR")
                    .font(.headline)
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
                    .opacity(coupon.cooldownExpirationDate ?? Date() > Date() ? 0.5 : 1.0) // 0.5 opacidad si está en cooldown
            }
            .disabled(coupon.cooldownExpirationDate ?? Date() > Date()) // Desactivar botón si está en cooldown

        }
        .padding(12)
        .alert(isPresented: $isRedeemConfirmationPresented) {
            Alert(
                title: Text("Confirmación de Canje"),
                message: Text("¿Estás seguro de que deseas canjear este cupón?"),
                primaryButton: .default(
                    Text("Canjear")
                ) {
                    // Actualiza el estado del cupón a "usado" en tu modelo
                    // Aquí deberías tener una función en tu ViewModel que actualice el cupón en Firestore.
//                    print("CuponID: \(coupon.id), CuponID Firebase: \()")
                    coupon.redeem()
                    authViewModel.couponViewModel.redeemCoupon(couponID: coupon.id, userID: authViewModel.userUID ?? "")
                },
                secondaryButton: .cancel()
            )
        }
    }
}

/*
struct CouponDetail_Previews: PreviewProvider {
    static var previews: some View {
        CouponDetail(coupon: Coupon(id: "1", title: "Cupón 1", category: "Categoría 1", description: "Descripción larga del cupón 1.", short_description: "Descripción corta 1.", imageName: "c1", used: false))
    }
}
*/
