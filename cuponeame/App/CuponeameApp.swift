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
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    init() {
        // Antes de crear los stores: AuthService toca Auth.auth() en su init.
        FirebaseApp.configure()
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        _auth = State(initialValue: AuthService())
        _store = State(initialValue: CouponStore())
        PushService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(store)
                .tint(CuponColors.brandPurple)
                .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

enum AppConfig {
    /// "1.0.0" leído del Info.plist.
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
