import XCTest
@testable import Cuponeame

/// El modo demo opera solo en memoria, así que se puede probar el store
/// completo (CRUD, canjeo, favoritos) sin tocar Firebase.
@MainActor
final class CouponStoreDemoTests: XCTestCase {

    private func makeDemoStore() -> CouponStore {
        let store = CouponStore()
        store.attachDemo()
        return store
    }

    func testDemoSeedsVariedStates() {
        let store = makeDemoStore()
        XCTAssertTrue(store.isDemo)
        XCTAssertEqual(store.coupons.count, DefaultCoupons.all.count)
        XCTAssertTrue(store.coupons.contains { $0.favorite }, "Falta el favorito de ejemplo")
        XCTAssertTrue(store.coupons.contains { $0.isOnCooldown() }, "Falta el cupón en espera")
        XCTAssertTrue(store.coupons.contains { $0.isExhausted }, "Falta el cupón agotado")
        XCTAssertEqual(store.redemptions.count, 2)
    }

    func testDemoCreateEditDelete() async {
        let store = makeDemoStore()
        let initial = store.coupons.count

        await store.save(Coupon(title: "Prueba",
                                shortDescription: "Cupón de prueba",
                                imageName: "/defaults-coupons/beso-cupon.jpg"))
        XCTAssertEqual(store.coupons.count, initial + 1)

        guard var created = store.coupons.first(where: { $0.title == "Prueba" }) else {
            return XCTFail("No se creó el cupón")
        }
        XCTAssertFalse(created.id.isEmpty)

        created.title = "Editado"
        await store.save(created)
        XCTAssertEqual(store.coupon(id: created.id)?.title, "Editado")
        XCTAssertEqual(store.coupons.count, initial + 1, "Editar no debe duplicar")

        await store.delete(created)
        XCTAssertNil(store.coupon(id: created.id))
        XCTAssertEqual(store.coupons.count, initial)
    }

    func testDemoRedeemStartsCooldownAndLogsHistory() async {
        let store = makeDemoStore()
        guard let coupon = store.coupons.first(where: { $0.canRedeem() && $0.cooldownTime != nil }) else {
            return XCTFail("No hay cupón canjeable con cooldown en la demo")
        }
        let redemptionsBefore = store.redemptions.count

        await store.redeem(coupon)

        let updated = store.coupon(id: coupon.id)
        XCTAssertEqual(updated?.redeemCount, coupon.redeemCount + 1)
        XCTAssertEqual(updated?.isOnCooldown(), true)
        XCTAssertEqual(store.redemptions.count, redemptionsBefore + 1)
        XCTAssertEqual(store.redemptions.first?.title, coupon.title)
    }

    func testDemoRedeemRespectsCooldownAndLimit() async {
        let store = makeDemoStore()
        let blocked = store.coupons.filter { !$0.canRedeem() }
        let redemptionsBefore = store.redemptions.count
        for coupon in blocked {
            await store.redeem(coupon)
        }
        XCTAssertEqual(store.redemptions.count, redemptionsBefore, "Un cupón bloqueado no debe canjearse")
    }

    func testDemoToggleFavorite() async {
        let store = makeDemoStore()
        guard let coupon = store.coupons.first(where: { !$0.favorite }) else {
            return XCTFail("No hay cupón sin favorito")
        }
        await store.toggleFavorite(coupon)
        XCTAssertEqual(store.coupon(id: coupon.id)?.favorite, true)
        await store.toggleFavorite(store.coupon(id: coupon.id)!)
        XCTAssertEqual(store.coupon(id: coupon.id)?.favorite, false)
    }

    func testDemoAddDefaultPack() async {
        let store = makeDemoStore()
        let initial = store.coupons.count
        await store.addDefaultPack()
        XCTAssertEqual(store.coupons.count, initial + DefaultCoupons.all.count)
    }

    func testDetachClearsDemo() {
        let store = makeDemoStore()
        store.detach()
        XCTAssertFalse(store.isDemo)
        XCTAssertTrue(store.coupons.isEmpty)
        XCTAssertTrue(store.redemptions.isEmpty)
    }
}
