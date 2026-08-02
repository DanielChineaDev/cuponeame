import XCTest
@testable import Cuponeame

final class InviteCodeTests: XCTestCase {

    func testGenerateProducesValidCodes() {
        for _ in 0..<100 {
            let code = InviteCode.generate()
            XCTAssertTrue(InviteCode.isValid(code), "Código inválido: \(code)")
        }
    }

    func testNormalizedCleansUserInput() {
        XCTAssertEqual(InviteCode.normalized(" amar-26 "), "AMAR26")
        XCTAssertEqual(InviteCode.normalized("a m a r 2 6"), "AMAR26")
        XCTAssertEqual(InviteCode.normalized("amar26extra"), "AMAR26")
        XCTAssertEqual(InviteCode.normalized(""), "")
    }

    func testValidationRejectsAmbiguousCharacters() {
        // 0, O, 1 e I no están en el alfabeto.
        XCTAssertFalse(InviteCode.isValid("AB0CDE"))
        XCTAssertFalse(InviteCode.isValid("ABOCDE"))
        XCTAssertFalse(InviteCode.isValid("ABC"))
        XCTAssertTrue(InviteCode.isValid("AMAR26"))
    }
}

final class AuthCryptoTests: XCTestCase {

    func testRandomNonceShape() {
        let nonce = AuthService.randomNonce()
        XCTAssertEqual(nonce.count, 32)
        let charset = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        XCTAssertTrue(nonce.allSatisfy { charset.contains($0) })
        XCTAssertNotEqual(nonce, AuthService.randomNonce(), "Dos nonces no deben coincidir")
    }

    func testSHA256KnownVector() {
        XCTAssertEqual(
            AuthService.sha256("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}

/// El modo demo del modo pareja funciona sin Firebase, así que se puede
/// probar el flujo completo de vinculación.
@MainActor
final class PartnerDemoTests: XCTestCase {

    private func makeDemoAuth() -> AuthService {
        let auth = AuthService()
        auth.enterDemo()
        return auth
    }

    func testDemoStartsUnlinked() {
        let auth = makeDemoAuth()
        XCTAssertNil(auth.partnerUID)
        XCTAssertNil(auth.partnerName)
    }

    func testDemoCreateInviteCode() async {
        let auth = makeDemoAuth()
        let code = await auth.createInviteCode()
        XCTAssertEqual(code, "AMAR26")
        XCTAssertTrue(InviteCode.isValid(code ?? ""))
    }

    func testDemoRedeemCodeLinksPartner() async {
        let auth = makeDemoAuth()
        let linked = await auth.redeemInviteCode("amar26")
        XCTAssertTrue(linked)
        XCTAssertEqual(auth.partnerName, "Pao")
        XCTAssertNotNil(auth.partnerUID)
    }

    func testDemoRedeemEmptyCodeFails() async {
        let auth = makeDemoAuth()
        let linked = await auth.redeemInviteCode("   ")
        XCTAssertFalse(linked)
        XCTAssertNil(auth.partnerName)
        XCTAssertNotNil(auth.errorMessage)
    }

    func testDemoPartnerAvatar() async {
        let auth = makeDemoAuth()
        let before = await auth.fetchPartnerAvatar()
        XCTAssertNil(before, "Sin vínculo no hay avatar de pareja")
        await auth.redeemInviteCode("AMAR26")
        let after = await auth.fetchPartnerAvatar()
        XCTAssertNotNil(after)
    }

    func testDemoUnlinkClearsPartner() async {
        let auth = makeDemoAuth()
        await auth.redeemInviteCode("AMAR26")
        await auth.unlinkPartner()
        XCTAssertNil(auth.partnerUID)
        XCTAssertNil(auth.partnerName)
    }

    func testDemoGiftSucceedsLocally() async {
        let store = CouponStore()
        store.attachDemo()
        let coupon = store.coupons[0]
        let sent = await store.gift(coupon, to: "demo-pareja", from: "Invitado")
        XCTAssertTrue(sent)
    }
}
