//
//  CouponViewModel.swift
//  cuponeame
//
//  Created by Blue on 7/9/23.
//

import Firebase
import FirebaseFirestore
import SwiftUI

class CouponViewModel: ObservableObject {
    @Published var isAvailable: Bool = true
    private var cooldownExpirationDate: Date?

    @Published var coupons: [Coupon] = [
        Coupon(id: "", title: "Atardecer", category: "Experiencias", description: "Disfruta de un impresionante atardecer en la playa que elijas. Relájate y deja que los colores del cielo te cautiven.", short_description: "Puesta de sol en la playa que más te guste.", imageName: "/defaults-coupons/atarceder-cupon.jpg", used: false, cooldownTime: 100, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "Cena/Almuerzo", category: "Comida", description: "Saborea una deliciosa cena o almuerzo en el restaurante de tu elección. Disfruta de exquisitos platillos y un ambiente acogedor.", short_description: "Una cena/almuerzo donde quieras.", imageName: "/defaults-coupons/cena-cupon.jpg", used: false, cooldownTime: 172800, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "",title: "Beso", category: "Romance", description: "Un beso puede expresar más que mil palabras. Este cupón te garantiza un beso apasionado y lleno de cariño. ¡Deja que tus emociones hablen por sí solas!", short_description: "Un beso de los infinitos.", imageName: "/defaults-coupons/beso-cupon.jpg", used: false, cooldownTime: 10800, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "Abrazo", category: "Romance", description: "Los abrazos son como un bálsamo para el alma. Este cupón te ofrece un abrazo cálido y reconfortante que te hará sentir querido y protegido.", short_description: "Un abrazo de los que te hacen volar.", imageName: "/defaults-coupons/abrazo-cupon.jpg", used: false, cooldownTime: 10800, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "No vale no", category: "Servicio Personalizado", description: "Con este cupón, no puedo negarme a ninguna de tus propuestas. ¡La decisión es tuya! Úsalo sabiamente y haz realidad tus deseos.", short_description: "No puedo decir no a nada que propongas.", imageName: "/defaults-coupons/novaleno-cupon.jpg", used: false, cooldownTime: 172800, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "Paseo de la mano", category: "Romance", description: "Caminar juntos de la mano es una experiencia única. Este cupón te invita a disfrutar de un romántico paseo junto al mar, creando recuerdos inolvidables.", short_description: "Un paseo de la mano junto al mar.", imageName: "/defaults-coupons/paseo-cupon.jpg", used: false, cooldownTime: 10800, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "Tarde de sexo", category: "Intimidad", description: "Una tarde de pasión y complicidad te espera con este cupón. Disfruta de un momento íntimo de conexión y diversión. ¡La química entre nosotros será inolvidable!", short_description: "Tarde de Netflix and Chill donde quieras.", imageName: "/defaults-coupons/sexo-cupon.jpg", used: false, cooldownTime: 1800, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "Mantita y peli", category: "Chill", description: "A veces, lo mejor es relajarse con una mantita y una buena película. Este cupón te garantiza una tarde de comodidad y entretenimiento en la mejor compañía.", short_description: "Tarde de mantita y peli.", imageName: "/defaults-coupons/mantapeli-cupon.jpg", used: false, cooldownTime: 172800, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "Cerveza", category: "Gastronomía", description: "Te invito a disfrutar de una refrescante cerveza en una terraza con ambiente acogedor. Brindaremos juntos por momentos especiales y conversaciones memorables.", short_description: "Te invito a una cervecita en una terraza.", imageName: "/defaults-coupons/cerveza-cupon.jpg", used: false, cooldownTime: 7200, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),
        
        Coupon(id: "", title: "Día de playa", category: "Experiencias", description: "Relájate y disfruta de un día completo en la playa. Elige el día que más te convenga y compartamos momentos de diversión, sol y mar.", short_description: "Iremos a la playa el día que quieras.", imageName: "/defaults-coupons/playa-cupon.jpg", used: false, cooldownTime: 86400, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5),

        Coupon(id: "", title: "Cine", category: "Entretenimiento", description: "Escoge la película que más te guste y los asientos más cómodos. Además, este cupón incluye un delicioso combo de palomitas para que disfrutes al máximo de la experiencia.", short_description: "Escoges la peli y los asientos. (Incluye palomitas).", imageName: "/defaults-coupons/cine-cupon.jpg", used: false, cooldownTime: 7200, cooldownExpirationDate: nil, redeemCount: 0, redeemLimit: 5)
    ]
    
    func loadUserCoupons(userID: String) {
        var userCoupons: [Coupon] = [] // Cambiado a una variable local
        
        let db = Firestore.firestore()
        let userCouponsRef = db.collection("users").document(userID).collection("coupons")

        userCouponsRef.getDocuments { (querySnapshot, error) in

            if let error = error {
                print("Error al obtener los cupones del usuario:", error.localizedDescription)
            } else {
                if let documents = querySnapshot?.documents {
                    userCoupons = documents.compactMap { document -> Coupon? in
                        guard let data = document.data() as? [String: Any] else { return nil }
                        let id = document.documentID as String
                        let title = data["title"] as? String ?? ""
                        let category = data["category"] as? String ?? ""
                        let description = data["description"] as? String ?? ""
                        let shortDescription = data["short_description"] as? String ?? ""
                        let imageName = data["imageName"] as? String ?? ""
                        let used = data["used"] as? Bool ?? false
                        let cooldownTime = data["cooldownTime"] as? TimeInterval
                        let cooldownExpirationDate = (data["cooldownExpirationDate"] as? Timestamp)?.dateValue()
                        let redeemCount = data["redeemCount"] as? Int ?? 0
                        let reddemLimit = data["redeemLimit"] as? Int ?? 5



                        let newCoupon = Coupon(id: id, title: title, category: category, description: description, short_description: shortDescription, imageName: imageName, used: used, cooldownTime: cooldownTime, cooldownExpirationDate: cooldownExpirationDate, redeemCount: redeemCount, redeemLimit: reddemLimit)

                        self.coupons.append(newCoupon)
                        return newCoupon
                    }

                    DispatchQueue.main.async {
                        self.coupons = userCoupons
                    }
                }
            }
        }
    }


    func redeemCoupon(couponID: String, userID: String, cooldownTime: TimeInterval) {
        let db = Firestore.firestore()
        let userCouponsRef = db.collection("users").document(userID).collection("coupons")
            
        let cooldownExpirationDate = Date().addingTimeInterval(cooldownTime)
            
        userCouponsRef.document(couponID).updateData([
            "used": true,
            "cooldownExpirationDate": cooldownExpirationDate,
            "redeemCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error al actualizar el cupón en Firestore: \(error.localizedDescription)")
            } else {
                print("Cupón canjeado exitosamente.")
            }
        }
    }


    func addDefaultCouponsToUser(userID: String) {
        let db = Firestore.firestore()

        let userCouponsRef = db.collection("users").document(userID).collection("coupons")

        for (_, coupon) in coupons.enumerated() {
            userCouponsRef.addDocument(data: [
                "title": coupon.title,
                "category": coupon.category,
                "description": coupon.description,
                "short_description": coupon.short_description,
                "imageName": coupon.imageName,
                "used": coupon.used,
                "cooldownTime": coupon.cooldownTime as Any,
                "cooldownExpirationDate": coupon.cooldownExpirationDate as Any,
                "redeemCount": coupon.redeemCount,
                "redeemLimit": coupon.redeemLimit
            ])
        }
    }
    
  
    func addDefaultCoupons() {
        let db = Firestore.firestore()
        
        for (index, coupon) in coupons.enumerated() {
            db.collection("coupons").document("coupon\(index)").setData([
                "title": coupon.title,
                "category": coupon.category,
                "description": coupon.description,
                "short_description": coupon.short_description,
                "imageName": coupon.imageName,
                "used": coupon.used,
                "cooldownTime": coupon.cooldownTime as Any,
                "cooldownExpirationDate": coupon.cooldownExpirationDate as Any,
                "redeemCount": coupon.redeemCount,
                "redeemLimit": coupon.redeemLimit
            ])
        }
    }
}
