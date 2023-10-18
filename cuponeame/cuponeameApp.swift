//
//  cuponeameApp.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct cuponeameApp: App { 
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.user != nil {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                ContentView()
                    .environmentObject(authViewModel)
            }
        }
    }
}


