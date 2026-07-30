//
//  CuponeameApp.swift
//  Cuponéame
//

import SwiftUI
import FirebaseCore

@main
struct CuponeameApp: App {
    @State private var auth: AuthService
    @State private var store: CouponStore

    init() {
        // Antes de crear los stores: AuthService toca Auth.auth() en su init.
        FirebaseApp.configure()
        _auth = State(initialValue: AuthService())
        _store = State(initialValue: CouponStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(store)
                .tint(CuponColors.brandPurple)
        }
    }
}

enum AppConfig {
    /// "1.0.0" leído del Info.plist.
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
