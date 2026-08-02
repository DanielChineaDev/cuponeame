import SwiftUI
import Observation
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

/// Publicidad de Cuponéame (patrón GasApp):
/// 1. Consentimiento UMP/RGPD antes de inicializar AdMob, luego ATT.
/// 2. **Intersticial** cada 3 aperturas de cupón, al salir del detalle.
/// 3. **Bonificado**: +3 creaciones de cupón cuando se agota la cuota.
/// Premium: nada de esto.
@MainActor
@Observable
final class AdsManager {
    private(set) var adsInitialized = false
    private(set) var rewardedReady = false
    /// El usuario está en una región donde puede reabrir el formulario RGPD.
    private(set) var privacyOptionsRequired = false

    private var gatherStarted = false
    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    private var couponOpens = 0
    private var lastInterstitialAt: Date?

    /// Banners en línea: cada pantalla necesita su PROPIA instancia (un UIView
    /// solo tiene un superview y las pestañas conviven montadas). `loaded` evita
    /// dejar un hueco vacío cuando no llega anuncio.
    enum BannerSlot: CaseIterable { case coupons, create, settings }
    private(set) var banners: [BannerSlot: BannerView] = [:]
    private(set) var bannerLoaded: [BannerSlot: Bool] = [:]
    private var bannerDelegates: [BannerSlot: BannerDelegate] = [:]

    func banner(_ slot: BannerSlot) -> BannerView? { banners[slot] }
    func isBannerLoaded(_ slot: BannerSlot) -> Bool { bannerLoaded[slot] ?? false }

    /// Margen mínimo entre intersticiales (no ametrallar al usuario).
    static let minGapSeconds: TimeInterval = 45

    // MARK: - Arranque

    func start(isPremium: Bool) async {
        // Hooks de desarrollo/capturas, como en GasApp.
        if ProcessInfo.processInfo.arguments.contains("-skipAds") { return }
        guard !gatherStarted, !isPremium else { return }
        gatherStarted = true

        if ProcessInfo.processInfo.arguments.contains("-forceAds") {
            await initializeAdMob()
            return
        }

        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            if let viewController = AuthService.topViewController() {
                try await ConsentForm.loadAndPresentIfRequired(from: viewController)
            }
        } catch {
            // Sin red o sin formulario: seguimos si UMP permite pedir anuncios.
        }
        privacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        guard ConsentInformation.shared.canRequestAds else { return }

        _ = await ATTrackingManager.requestTrackingAuthorization()
        await initializeAdMob()
    }

    /// Reabre el formulario de consentimiento (RGPD exige poder cambiarlo).
    func presentPrivacyOptions() async {
        guard let viewController = AuthService.topViewController() else { return }
        try? await ConsentForm.presentPrivacyOptionsForm(from: viewController)
    }

    private func initializeAdMob() async {
        await withCheckedContinuation { continuation in
            MobileAds.shared.start { _ in continuation.resume() }
        }
        adsInitialized = true
        #if DEBUG
        NSLog("AdsDebug: AdMob inicializado")
        #endif
        makeBanners()
        preloadInterstitial()
        preloadRewarded()
    }

    /// El usuario compró premium: cortar la publicidad en caliente.
    func disableForPremium() {
        interstitial = nil
        rewarded = nil
        rewardedReady = false
        banners = [:]
        bannerLoaded = [:]
        bannerDelegates = [:]
    }

    // MARK: - Banners

    private func makeBanners() {
        // Ancho de la ventana real (UIScreen.main miente en Split View).
        let windowWidth = AuthService.topViewController()?.view.window?.bounds.width ?? 393
        for slot in BannerSlot.allCases {
            // Al ancho del contenido (padding lateral de 16 en las pantallas).
            let banner = BannerView(
                adSize: currentOrientationAnchoredAdaptiveBanner(width: windowWidth - 32))
            banner.adUnitID = AppConfig.admobBannerUnit
            let delegate = BannerDelegate()
            delegate.onLoad = { [weak self] loaded in self?.bannerLoaded[slot] = loaded }
            banner.delegate = delegate
            bannerDelegates[slot] = delegate
            banners[slot] = banner
        }
        // La carga se dispara al aparecer la ranura en pantalla: ahí sí hay
        // rootViewController (al arrancar la ventana aún no existe).
    }

    /// La pantalla con la ranura apareció: engancha el controlador y carga.
    func activateBanner(_ slot: BannerSlot, isPremium: Bool) {
        #if DEBUG
        NSLog("AdsDebug: activateBanner premium=%d init=%d banner=%d vc=%d",
              isPremium ? 1 : 0, adsInitialized ? 1 : 0,
              banners[slot] != nil ? 1 : 0,
              AuthService.topViewController() != nil ? 1 : 0)
        #endif
        guard !isPremium, adsInitialized,
              let banner = banners[slot],
              let viewController = AuthService.topViewController() else { return }
        // Ya cargado: nada que hacer (evita repetir peticiones al volver a la tab).
        guard bannerLoaded[slot] != true else { return }
        banner.rootViewController = viewController
        banner.load(Request())
    }

    // MARK: - Intersticial (cada 3 cupones abiertos)

    private func preloadInterstitial() {
        guard adsInitialized else { return }
        InterstitialAd.load(with: AppConfig.admobInterstitialUnit, request: Request()) { [weak self] ad, _ in
            Task { @MainActor in self?.interstitial = ad }
        }
    }

    /// Una vez por apertura del detalle de cupón.
    func registerCouponOpen() {
        couponOpens += 1
    }

    /// Al salir del detalle: muestra si toca (múltiplo de 3), hay anuncio
    /// precargado y pasó el margen mínimo. Nunca bloquea la navegación.
    func maybeShowInterstitial(isPremium: Bool) {
        guard !isPremium, adsInitialized,
              couponOpens > 0,
              couponOpens % MonetizationStore.interstitialEvery == 0,
              let ad = interstitial,
              lastInterstitialAt.map({ Date().timeIntervalSince($0) >= Self.minGapSeconds }) ?? true,
              let viewController = AuthService.topViewController() else { return }
        interstitial = nil
        lastInterstitialAt = Date()
        ad.present(from: viewController)
        preloadInterstitial()
    }

    // MARK: - Bonificado (+3 creaciones)

    private func preloadRewarded() {
        guard adsInitialized else { return }
        RewardedAd.load(with: AppConfig.admobRewardedUnit, request: Request()) { [weak self] ad, _ in
            Task { @MainActor in
                self?.rewarded = ad
                self?.rewardedReady = ad != nil
            }
        }
    }

    /// Muestra el bonificado; devuelve true si el usuario se ganó la recompensa.
    func showRewarded() async -> Bool {
        guard let ad = rewarded, let viewController = AuthService.topViewController() else {
            return false
        }
        rewarded = nil
        rewardedReady = false
        var earned = false
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ad.present(from: viewController) {
                earned = true
                continuation.resume()
            }
        }
        preloadRewarded()
        return earned
    }
}

/// Delegado del banner: avisa cuando recibe o falla un anuncio.
private final class BannerDelegate: NSObject, BannerViewDelegate {
    var onLoad: ((Bool) -> Void)?

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        Task { @MainActor in onLoad?(true) }
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        #if DEBUG
        NSLog("AdsDebug: banner falló: %@", error.localizedDescription)
        #endif
        Task { @MainActor in onLoad?(false) }
    }
}

/// Banner adaptativo (instancia gestionada por AdsManager).
struct BannerAdView: UIViewRepresentable {
    let banner: BannerView

    func makeUIView(context: Context) -> BannerView { banner }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

/// Ranura de banner para meter en el contenido: no ocupa nada si el usuario es
/// premium, si AdMob no arrancó o si el anuncio no llegó.
struct BannerSlotView: View {
    let slot: AdsManager.BannerSlot

    @Environment(AdsManager.self) private var ads
    @Environment(MonetizationStore.self) private var monetization

    var body: some View {
        // Sin anuncio no ocupa NADA (ni el espaciado del contenedor): la carga
        // la dispara la pantalla con `.activateBannerSlot(_:)`, no esta vista,
        // porque un Group vacío es EmptyView y no recibiría onAppear.
        if !monetization.isPremium, ads.adsInitialized,
           ads.isBannerLoaded(slot), let banner = ads.banner(slot) {
            BannerAdView(banner: banner)
                .frame(width: banner.adSize.size.width, height: banner.adSize.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        }
    }
}

extension View {
    /// La pantalla pide su banner al aparecer (y cuando AdMob termina de
    /// inicializar). Va en la pantalla, no en la ranura, para que la ranura
    /// pueda desaparecer del todo si no hay anuncio.
    func activateBannerSlot(_ slot: AdsManager.BannerSlot) -> some View {
        modifier(ActivateBannerSlot(slot: slot))
    }
}

private struct ActivateBannerSlot: ViewModifier {
    let slot: AdsManager.BannerSlot

    @Environment(AdsManager.self) private var ads
    @Environment(MonetizationStore.self) private var monetization

    func body(content: Content) -> some View {
        content
            .onAppear { ads.activateBanner(slot, isPremium: monetization.isPremium) }
            .onChange(of: ads.adsInitialized) { _, _ in
                ads.activateBanner(slot, isPremium: monetization.isPremium)
            }
    }
}
