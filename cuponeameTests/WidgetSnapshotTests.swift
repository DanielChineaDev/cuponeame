import XCTest
@testable import Cuponeame

final class WidgetSnapshotTests: XCTestCase {

    func testRoundTripThroughUserDefaults() {
        let defaults = UserDefaults(suiteName: "test-widget-snapshot")!
        defaults.removePersistentDomain(forName: "test-widget-snapshot")

        let snapshot = WidgetSnapshot(
            updated: Date(timeIntervalSince1970: 1_690_000_000),
            total: 11,
            available: 9,
            next: .init(title: "Beso", category: "Romance",
                        categoryIcon: "heart.fill", remainingUses: 3))

        snapshot.save(defaults: defaults)
        XCTAssertEqual(WidgetSnapshot.load(defaults: defaults), snapshot)
    }

    func testLoadReturnsNilWithoutData() {
        let defaults = UserDefaults(suiteName: "test-widget-empty")!
        defaults.removePersistentDomain(forName: "test-widget-empty")
        XCTAssertNil(WidgetSnapshot.load(defaults: defaults))
    }
}

@MainActor
final class AvatarAndGiftDemoTests: XCTestCase {

    func testDemoUpdateAvatar() async {
        let auth = AuthService()
        auth.enterDemo()
        XCTAssertNil(auth.avatar)
        await auth.updateAvatar("🦊")
        XCTAssertEqual(auth.avatar, "🦊")
        await auth.updateAvatar(nil)
        XCTAssertNil(auth.avatar)
    }

    func testDemoGiftGetsPaoReplyAndAnnouncesIt() async throws {
        let store = CouponStore()
        store.attachDemo()
        let initialCount = store.coupons.count
        XCTAssertNil(store.incomingGift)

        let sent = await store.gift(store.coupons[0], to: "demo-pareja", from: "Invitado")
        XCTAssertTrue(sent)

        // Pao responde a los ~2 s con un regalo firmado.
        try await Task.sleep(for: .seconds(3))
        XCTAssertEqual(store.coupons.count, initialCount + 1)
        let gift = try XCTUnwrap(store.incomingGift)
        XCTAssertEqual(gift.from, "Pao")
        XCTAssertTrue(store.coupons.contains { $0.id == gift.id })
    }
}
