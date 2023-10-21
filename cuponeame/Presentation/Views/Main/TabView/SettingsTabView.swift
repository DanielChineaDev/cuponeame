//
//  SettingsTabView.swift
//  cuponeame
//
//  Created by Blue on 18/10/23.
//

import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        Text("Pestaña 3")
            .tabItem {
                Image(systemName: "gearshape.circle.fill")
                Text("Ajustes")
            }
            .tag(2)
    }
}
