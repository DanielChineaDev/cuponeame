//
//  CouponCard.swift
//  cuponeame
//
//  Created by Blue on 26/8/23.
//

import SwiftUI

struct CouponCard: View {
    let coupon: Coupon
    
    var body: some View {        
        VStack {
            VStack (alignment: .leading, spacing: 10){
                Text(coupon.title)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                
                
                Text(coupon.category)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack {
                    Text(coupon.short_description)
                        .multilineTextAlignment(.leading)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 225)
            .foregroundColor(.white)


        }
        .padding(25)
        .frame(maxWidth: .infinity, minHeight: 225)
        .background(
            ZStack{
                Image(coupon.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            
        )
        .cornerRadius(40)
        .shadow(radius: 5)
    }
}

/*
struct CouponCard_Previews: PreviewProvider {
    static var previews: some View {
        CouponCard(coupon: Coupon(id: "", title: "Cupón 1", category: "Categoría 1", description: "Descripción larga del cupón 1.", short_description: "Descripción corta 1.", imageName: "c1", used: false))
    }
}
*/
