import XCTest
@testable import Cuponeame

@MainActor
final class MonetizationTests: XCTestCase {

    private func makeStore(name: String = #function) -> MonetizationStore {
        let suite = "monetization-test-\(name)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return MonetizationStore(defaults: defaults)
    }

    func testStartsWithMonthlyQuota() {
        let store = makeStore()
        XCTAssertFalse(store.isPremium)
        XCTAssertEqual(store.remaining, MonetizationStore.monthlyQuota)
        XCTAssertTrue(store.canCreate)
    }

    func testConsumeUntilExhausted() {
        let store = makeStore()
        for expected in stride(from: MonetizationStore.monthlyQuota - 1, through: 0, by: -1) {
            XCTAssertTrue(store.consumeCreation())
            XCTAssertEqual(store.remaining, expected)
        }
        XCTAssertFalse(store.canCreate)
        XCTAssertFalse(store.consumeCreation(), "Sin cuota no se debe poder crear")
    }

    func testRewardGrantsExtraCreations() {
        let store = makeStore()
        for _ in 0..<MonetizationStore.monthlyQuota { store.consumeCreation() }
        XCTAssertFalse(store.canCreate)

        store.grantReward()
        XCTAssertEqual(store.remaining, MonetizationStore.rewardBonus)
        XCTAssertTrue(store.consumeCreation())
    }

    func testPremiumIsUnlimited() {
        let store = makeStore()
        store.setPremium(true)
        for _ in 0..<50 {
            XCTAssertTrue(store.consumeCreation())
        }
        XCTAssertTrue(store.canCreate)
        XCTAssertEqual(store.quotaLabel, "Cupones ilimitados")
    }

    func testMonthlyRolloverResetsQuotaAndBonus() {
        let store = makeStore()
        store.consumeCreation()
        store.grantReward()
        XCTAssertLessThan(store.remaining, MonetizationStore.monthlyQuota + MonetizationStore.rewardBonus + 1)

        // Un mes después: cuota nueva, extra caducado.
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        store.rolloverIfNeeded(now: nextMonth)
        XCTAssertEqual(store.remaining, MonetizationStore.monthlyQuota)
    }

    func testPeriodKeyFormat() {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 3
        parts.day = 15
        let date = Calendar.current.date(from: parts)!
        XCTAssertEqual(MonetizationStore.periodKey(for: date), "2026-03")
    }

    func testQuotaLabelCountsBonus() {
        let store = makeStore()
        store.grantReward()
        XCTAssertEqual(
            store.quotaLabel,
            "\(MonetizationStore.monthlyQuota + MonetizationStore.rewardBonus) de \(MonetizationStore.monthlyQuota + MonetizationStore.rewardBonus) cupones este mes")
    }
}
