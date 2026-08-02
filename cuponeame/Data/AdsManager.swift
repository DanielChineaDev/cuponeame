import Foundation
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

    private var gatherStarted = false
    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    private var couponOpens = 0
    private var lastInterstitialAt: Date?

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
        guard ConsentInformation.shared.canRequestAds else { return }

        _ = await ATTrackingManager.requestTrackingAuthorization()
        await initializeAdMob()
    }

    private func initializeAdMob() async {
        await withCheckedContinuation { continuation in
            MobileAds.shared.start { _ in continuation.resume() }
        }
        adsInitialized = true
        preloadInterstitial()
        preloadRewarded()
    }

    /// El usuario compró premium: cortar la publicidad en caliente.
    func disableForPremium() {
        interstitial = nil
        rewarded = nil
        rewardedReady = false
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
