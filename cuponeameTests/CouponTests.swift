import XCTest
@testable import Cuponeame

final class CouponTests: XCTestCase {

    // MARK: - Canjeo

    func testFreshCouponCanBeRedeemed() {
        let coupon = Coupon(id: "a", title: "Beso", redeemCount: 0, redeemLimit: 5)
        XCTAssertTrue(coupon.canRedeem())
        XCTAssertFalse(coupon.isExhausted)
        XCTAssertFalse(coupon.isOnCooldown())
    }

    func testCooldownBlocksRedeem() {
        let now = Date()
        let coupon = Coupon(id: "a", cooldownTime: 3600,
                            cooldownExpirationDate: now.addingTimeInterval(120))
        XCTAssertTrue(coupon.isOnCooldown(now: now))
        XCTAssertFalse(coupon.canRedeem(now: now))
        XCTAssertEqual(coupon.remainingCooldownText(now: now), "00:02:00")
    }

    func testExpiredCooldownAllowsRedeem() {
        let now = Date()
        let coupon = Coupon(id: "a", cooldownExpirationDate: now.addingTimeInterval(-1))
        XCTAssertFalse(coupon.isOnCooldown(now: now))
        XCTAssertTrue(coupon.canRedeem(now: now))
        XCTAssertEqual(coupon.remainingCooldown(now: now), 0)
    }

    func testExhaustedCouponCannotBeRedeemed() {
        let coupon = Coupon(id: "a", redeemCount: 5, redeemLimit: 5)
        XCTAssertTrue(coupon.isExhausted)
        XCTAssertFalse(coupon.canRedeem())
    }

    func testProgress() {
        XCTAssertEqual(Coupon(id: "a", redeemCount: 0, redeemLimit: 5).progress, 0)
        XCTAssertEqual(Coupon(id: "a", redeemCount: 2, redeemLimit: 4).progress, 0.5)
        XCTAssertEqual(Coupon(id: "a", redeemCount: 9, redeemLimit: 5).progress, 1)
        XCTAssertEqual(Coupon(id: "a", redeemCount: 1, redeemLimit: 0).progress, 0)
    }

    // MARK: - Código de barras

    func testBarcodeIsStableAndTenDigits() {
        let coupon = Coupon(id: "abc123")
        XCTAssertEqual(coupon.barcode, Coupon(id: "abc123").barcode)
        XCTAssertEqual(coupon.barcode.count, 10)
        XCTAssertTrue(coupon.barcode.allSatisfy(\.isNumber))
        XCTAssertNotEqual(coupon.barcode, Coupon(id: "abc124").barcode)
    }

    // MARK: - Contrato Firestore

    func testFirestoreRoundTrip() {
        var original = Coupon(
            id: "doc1",
            title: "Cine",
            category: "Entretenimiento",
            description: "Peli y palomitas",
            shortDescription: "Escoges tú",
            imageName: "/defaults-coupons/cine-cupon.jpg",
            used: true,
            cooldownTime: 7200,
            cooldownExpirationDate: Date(timeIntervalSince1970: 1_700_000_000),
            redeemCount: 2,
            redeemLimit: 5,
            favorite: true)
        original.createdAt = Date(timeIntervalSince1970: 1_690_000_000)

        let restored = Coupon(id: "doc1", data: original.firestoreData)

        XCTAssertEqual(restored, original)
    }

    func testFirestoreParsesLegacyDocumentWithoutNewFields() {
        // Documento creado por la versión 2023: sin favorite ni createdAt.
        let legacy: [String: Any] = [
            "title": "Beso",
            "category": "Romance",
            "description": "Un beso",
            "short_description": "Corta",
            "imageName": "/defaults-coupons/beso-cupon.jpg",
            "used": false,
            "cooldownTime": 10800.0,
            "redeemCount": 1,
            "redeemLimit": 5,
        ]

        let coupon = Coupon(id: "old", data: legacy)

        XCTAssertEqual(coupon.title, "Beso")
        XCTAssertEqual(coupon.shortDescription, "Corta")
        XCTAssertFalse(coupon.favorite)
        XCTAssertNil(coupon.createdAt)
        XCTAssertNil(coupon.cooldownExpirationDate)
        XCTAssertEqual(coupon.redeemLimit, 5)
    }

    // MARK: - Catálogo por defecto

    func testDefaultCatalog() {
        XCTAssertEqual(DefaultCoupons.all.count, 11)
        let titles = Set(DefaultCoupons.all.map(\.title))
        XCTAssertEqual(titles.count, DefaultCoupons.all.count, "Títulos duplicados en el catálogo")
        for coupon in DefaultCoupons.all {
            XCTAssertTrue(coupon.imageName.hasPrefix("/defaults-coupons/"))
            XCTAssertNotNil(CouponCategory(rawValue: coupon.category),
                            "Categoría desconocida: \(coupon.category)")
        }
    }

    func testDefaultImagesExistInCatalog() {
        for path in DefaultCoupons.imageOptions {
            XCTAssertNotNil(ImageService.bundledName(for: path),
                            "Falta el asset local para \(path)")
        }
    }

    // MARK: - Historial

    func testHistoryDayTitles() {
        XCTAssertEqual(HistoryScreen.dayTitle(for: Date()), "Hoy")
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(HistoryScreen.dayTitle(for: yesterday), "Ayer")
    }
}
