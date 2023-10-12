//
//  Cupon.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import Foundation

class Coupon: Identifiable, Decodable, ObservableObject {
    var id: String = ""
    var title: String = ""
    var category: String = ""
    var description: String = ""
    var short_description: String = ""
    var imageName: String = ""
    @Published var used: Bool
    @Published var cooldownTime: Date?
    @Published var cooldownExpirationDate: Date?
    
    func redeem() {
        self.used = true
        self.cooldownExpirationDate = Date().addingTimeInterval(86400) // 24 horas de cooldown
    }

    func isAvailable() -> Bool {
        guard let expirationDate = cooldownExpirationDate else { return true }
        return Date() > expirationDate
    }
}



