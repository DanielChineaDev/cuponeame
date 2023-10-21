//
//  ButtonStyleView.swift
//  cuponeame
//
//  Created by Blue on 18/10/23.
//

import SwiftUI

import SwiftUI

struct BlurButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(BlurView(style: .systemMaterial))
            .foregroundColor(.primary)
            .cornerRadius(20)
    }
}



struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(BlurView(style: .regular))
            .foregroundColor(.white)
            .cornerRadius(20)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<BlurView>) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct ButtonStyleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Image("background_home")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Button("PRINCIPAL", action: {})
                    .buttonStyle(BlurButtonStyle())
                
                Button("SECUNDARIO", action: {})
                    .buttonStyle(OutlineButtonStyle())
            }
            .padding()
        }
    }
}

