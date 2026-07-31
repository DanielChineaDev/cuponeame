import Foundation

/// Idea prellenada para estrenar el formulario de Crear con un toque.
struct CouponTemplate: Identifiable {
    let id = UUID()
    let title: String
    let shortDescription: String
    let description: String
    let category: CouponCategory
    let imageName: String
    let cooldown: TimeInterval?
    /// Icono SF para la tarjeta de la idea en el hub.
    let icon: String

    static let all: [CouponTemplate] = [
        CouponTemplate(
            title: "Masaje relajante",
            shortDescription: "Un masaje de 20 minutos donde quieras.",
            description: "Túmbate y desconecta: 20 minutos de masaje para dejar el día atrás.",
            category: .romance, imageName: "/defaults-coupons/abrazo-cupon.jpg",
            cooldown: 86400, icon: "hands.and.sparkles.fill"),
        CouponTemplate(
            title: "Desayuno en la cama",
            shortDescription: "Te lo llevo a la cama, tú no te mueves.",
            description: "Café, tostadas y mimos sin salir de las sábanas. Tú solo despiertas.",
            category: .comida, imageName: "/defaults-coupons/cena-cupon.jpg",
            cooldown: 172800, icon: "cup.and.saucer.fill"),
        CouponTemplate(
            title: "Noche de peli",
            shortDescription: "Eliges la peli y las palomitas.",
            description: "Manta, sofá y la película que tú digas. Palomitas incluidas.",
            category: .chill, imageName: "/defaults-coupons/mantapeli-cupon.jpg",
            cooldown: 43200, icon: "film.fill"),
        CouponTemplate(
            title: "Paseo al atardecer",
            shortDescription: "Un paseo de la mano viendo la puesta de sol.",
            description: "Nos escapamos a ver el atardecer, sin prisa y de la mano.",
            category: .experiencias, imageName: "/defaults-coupons/atarceder-cupon.jpg",
            cooldown: 86400, icon: "sun.horizon.fill"),
        CouponTemplate(
            title: "Cena sorpresa",
            shortDescription: "Yo cocino, tú disfrutas.",
            description: "Una cena preparada con cariño en casa. Tú solo pones el hambre.",
            category: .comida, imageName: "/defaults-coupons/cena-cupon1.jpg",
            cooldown: 172800, icon: "fork.knife"),
        CouponTemplate(
            title: "Comodín \"sí\"",
            shortDescription: "No puedo decir que no a lo que propongas.",
            description: "Un cupón para cuando quieras salirte con la tuya. No hay negativa posible.",
            category: .personalizado, imageName: "/defaults-coupons/novaleno-cupon.jpg",
            cooldown: 604800, icon: "checkmark.seal.fill"),
    ]
}
