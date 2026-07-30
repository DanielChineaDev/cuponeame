import Foundation

/// Pack de cupones con el que estrena la app cada cuenta nueva.
/// Las rutas `/defaults-coupons/…` son el contrato con Firebase Storage y con
/// las cuentas antiguas; cada una tiene además su imagen local en el catálogo.
enum DefaultCoupons {
    static let all: [Coupon] = [
        Coupon(title: "Atardecer", category: "Experiencias",
               description: "Disfruta de un impresionante atardecer en la playa que elijas. Relájate y deja que los colores del cielo te cautiven.",
               shortDescription: "Puesta de sol en la playa que más te guste.",
               imageName: "/defaults-coupons/atarceder-cupon.jpg",
               cooldownTime: 100, redeemLimit: 5),

        Coupon(title: "Cena/Almuerzo", category: "Comida",
               description: "Saborea una deliciosa cena o almuerzo en el restaurante de tu elección. Disfruta de exquisitos platillos y un ambiente acogedor.",
               shortDescription: "Una cena/almuerzo donde quieras.",
               imageName: "/defaults-coupons/cena-cupon.jpg",
               cooldownTime: 172800, redeemLimit: 5),

        Coupon(title: "Beso", category: "Romance",
               description: "Un beso puede expresar más que mil palabras. Este cupón te garantiza un beso apasionado y lleno de cariño. ¡Deja que tus emociones hablen por sí solas!",
               shortDescription: "Un beso de los infinitos.",
               imageName: "/defaults-coupons/beso-cupon.jpg",
               cooldownTime: 10800, redeemLimit: 5),

        Coupon(title: "Abrazo", category: "Romance",
               description: "Los abrazos son como un bálsamo para el alma. Este cupón te ofrece un abrazo cálido y reconfortante que te hará sentir querido y protegido.",
               shortDescription: "Un abrazo de los que te hacen volar.",
               imageName: "/defaults-coupons/abrazo-cupon.jpg",
               cooldownTime: 10800, redeemLimit: 5),

        Coupon(title: "No vale no", category: "Servicio Personalizado",
               description: "Con este cupón, no puedo negarme a ninguna de tus propuestas. ¡La decisión es tuya! Úsalo sabiamente y haz realidad tus deseos.",
               shortDescription: "No puedo decir no a nada que propongas.",
               imageName: "/defaults-coupons/novaleno-cupon.jpg",
               cooldownTime: 172800, redeemLimit: 5),

        Coupon(title: "Paseo de la mano", category: "Romance",
               description: "Caminar juntos de la mano es una experiencia única. Este cupón te invita a disfrutar de un romántico paseo junto al mar, creando recuerdos inolvidables.",
               shortDescription: "Un paseo de la mano junto al mar.",
               imageName: "/defaults-coupons/paseo-cupon.jpg",
               cooldownTime: 10800, redeemLimit: 5),

        Coupon(title: "Tarde de sexo", category: "Intimidad",
               description: "Una tarde de pasión y complicidad te espera con este cupón. Disfruta de un momento íntimo de conexión y diversión. ¡La química entre nosotros será inolvidable!",
               shortDescription: "Tarde de Netflix and Chill donde quieras.",
               imageName: "/defaults-coupons/sexo-cupon.jpg",
               cooldownTime: 1800, redeemLimit: 5),

        Coupon(title: "Mantita y peli", category: "Chill",
               description: "A veces, lo mejor es relajarse con una mantita y una buena película. Este cupón te garantiza una tarde de comodidad y entretenimiento en la mejor compañía.",
               shortDescription: "Tarde de mantita y peli.",
               imageName: "/defaults-coupons/mantapeli-cupon.jpg",
               cooldownTime: 172800, redeemLimit: 5),

        Coupon(title: "Cerveza", category: "Gastronomía",
               description: "Te invito a disfrutar de una refrescante cerveza en una terraza con ambiente acogedor. Brindaremos juntos por momentos especiales y conversaciones memorables.",
               shortDescription: "Te invito a una cervecita en una terraza.",
               imageName: "/defaults-coupons/cerveza-cupon.jpg",
               cooldownTime: 7200, redeemLimit: 5),

        Coupon(title: "Día de playa", category: "Experiencias",
               description: "Relájate y disfruta de un día completo en la playa. Elige el día que más te convenga y compartamos momentos de diversión, sol y mar.",
               shortDescription: "Iremos a la playa el día que quieras.",
               imageName: "/defaults-coupons/playa-cupon.jpg",
               cooldownTime: 86400, redeemLimit: 5),

        Coupon(title: "Cine", category: "Entretenimiento",
               description: "Escoge la película que más te guste y los asientos más cómodos. Además, este cupón incluye un delicioso combo de palomitas para que disfrutes al máximo de la experiencia.",
               shortDescription: "Escoges la peli y los asientos. (Incluye palomitas).",
               imageName: "/defaults-coupons/cine-cupon.jpg",
               cooldownTime: 7200, redeemLimit: 5),
    ]

    /// Imágenes locales disponibles al crear un cupón nuevo.
    static let imageOptions: [String] = [
        "/defaults-coupons/atarceder-cupon.jpg",
        "/defaults-coupons/cena-cupon.jpg",
        "/defaults-coupons/cena-cupon1.jpg",
        "/defaults-coupons/beso-cupon.jpg",
        "/defaults-coupons/abrazo-cupon.jpg",
        "/defaults-coupons/novaleno-cupon.jpg",
        "/defaults-coupons/paseo-cupon.jpg",
        "/defaults-coupons/sexo-cupon.jpg",
        "/defaults-coupons/mantapeli-cupon.jpg",
        "/defaults-coupons/cerveza-cupon.jpg",
        "/defaults-coupons/playa-cupon.jpg",
        "/defaults-coupons/cine-cupon.jpg",
    ]
}
