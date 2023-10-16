import SwiftUI

struct CardView: View {
    let coupon: Coupon    
    @State private var progressValue: Double = 0.3 // por ejemplo, 70% completado
    @ObservedObject private var imageLoader = ImageLoader()

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    VStack (alignment: .leading){
                        Text(coupon.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                        
                        Text(coupon.category)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    
                    Spacer()
                
                    VStack {
                        Image(systemName: "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    
                        Spacer()
                        
                        CircleProgressBar(progress: $progressValue)
                            .frame(width: 32, height: 32)
                            .padding(.leading, 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            imageLoader.image?
                .resizable()
                .aspectRatio(contentMode: .fill)
                .cornerRadius(20)
                .clipped()
            // placeholder en caso de que la imagen no esté cargada
        )
        .onAppear {
            imageLoader.downloadImageFromFirebase(imageName: coupon.imageName)
        }
        .frame(maxWidth: .infinity, minHeight: 230, maxHeight: 230)
        .background(
            Image(coupon.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill) // Cambiar de .fill a .fit aquí
                .cornerRadius(20)
                .clipped()
        )
        .frame(maxWidth: .infinity, minHeight: 230, maxHeight: 230)
        .cornerRadius(20)
    }
}


struct CircleProgressBar: View {
    @Binding var progress: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .opacity(0.3)
                .foregroundColor(Color.white)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.white)
                .rotationEffect(Angle(degrees: 270.0))
                .rotation3DEffect(Angle(degrees: 0), axis: (x: 1, y: 0, z: 0))
                .animation(.linear(duration: 0.2), value: self.progress)
        }
    }
}


//struct Content: View {
//    var body: some View {
//        CardView(title: "Ir a tomer cervecita", category: "Gastronomía", short_description: "Esto es una descripcion corta de lo que podria ser un real.", imageName: "cerveza-cupon")
//    }
//}
//
//struct Content_Previews: PreviewProvider {
//    static var previews: some View {
//        Content()
//    }
//}

