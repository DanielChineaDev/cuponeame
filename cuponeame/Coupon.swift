//
//  Cupon.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import Foundation

class Coupon: Identifiable, ObservableObject {
    var id: String
    var title: String
    var category: String
    var description: String
    var short_description: String
    var imageName: String
    @Published var used: Bool
    @Published var cooldownTime: TimeInterval?
    @Published var cooldownExpirationDate: Date?
    
    init(id: String, title: String, category: String, description: String, short_description: String, imageName: String, used: Bool, cooldownTime: TimeInterval?, cooldownExpirationDate: Date?) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.short_description = short_description
        self.imageName = imageName
        self.used = used
        self.cooldownTime = cooldownTime
        self.cooldownExpirationDate = cooldownExpirationDate
    }
    
    func redeem() {
        self.used = true
        if let cooldown = cooldownTime {
            self.cooldownExpirationDate = Date().addingTimeInterval(cooldown)
        }
    }

    func isAvailable() -> Bool {
        guard let expirationDate = cooldownExpirationDate else { return true }
        return Date() > expirationDate
    }
     
}





