//
//  CreateTabView.swift
//  cuponeame
//
//  Created by Blue on 18/10/23.
//

import SwiftUI

struct CreateTabView: View {
    var body: some View {
        Text("Pestaña 2")
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Crear")
            }
            .tag(1)
    }
}
