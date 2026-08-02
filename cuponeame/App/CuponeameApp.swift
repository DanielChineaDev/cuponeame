//
//  CuponeameApp.swift
//  Cuponéame
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct CuponeameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var auth: AuthService
    @State private var store: CouponStore
    @State private var monetization: MonetizationStore
    @State private var ads = AdsManager()
    @State private var purchases: PurchaseManager
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    init() {
        // Antes de crear los stores: AuthService toca Auth.auth() en su init.
        FirebaseApp.configure()
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        _auth = State(initialValue: AuthService())
        _store = State(initialValue: CouponStore())
        let monetization = MonetizationStore()
        _monetization = State(initialValue: monetization)
        _purchases = State(initialValue: PurchaseManager(monetization: monetization))
        PushService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(store)
                .environment(monetization)
                .environment(ads)
                .environment(purchases)
                .tint(CuponColors.brandPurple)
                .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    monetization.rolloverIfNeeded()
                    await purchases.refreshEntitlements()
                    await purchases.load()
                    await ads.start(isPremium: monetization.isPremium)
                }
                .onChange(of: monetization.isPremium) { _, premium in
                    if premium { ads.disableForPremium() }
                }
        }
    }
}

enum AppConfig {
    /// "1.0.0" leído del Info.plist.
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// Compra única que quita anuncios y desbloquea cupones ilimitados.
    static let premiumProductId = "com.bpo.cuponeame.premium"

    // Documentos legales (los mismos que se declaran en App Store Connect).
    static let privacyPolicyURL = URL(string: "https://github.com/DanielChineaDev/cuponeame/blob/main/docs/PRIVACIDAD.md")!
    static let termsURL = URL(string: "https://github.com/DanielChineaDev/cuponeame/blob/main/docs/TERMINOS.md")!

    // Unidades de AdMob. Por defecto, los IDs de PRUEBA de Google: sustituir
    // por los reales en Config/Secrets.xcconfig (ADMOB_INTERSTITIAL_UNIT,
    // ADMOB_REWARDED_UNIT) antes de publicar.
    static var admobInterstitialUnit: String {
        infoString("ADMOB_INTERSTITIAL_UNIT") ?? "ca-app-pub-3940256099942544/4411468910"
    }

    static var admobRewardedUnit: String {
        infoString("ADMOB_REWARDED_UNIT") ?? "ca-app-pub-3940256099942544/1712485313"
    }

    static var admobBannerUnit: String {
        infoString("ADMOB_BANNER_UNIT") ?? "ca-app-pub-3940256099942544/2934735716"
    }

    private static func infoString(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty, value.hasPrefix("ca-app-pub") else { return nil }
        return value
    }
}
