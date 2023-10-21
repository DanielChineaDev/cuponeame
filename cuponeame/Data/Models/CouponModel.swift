//
//  Cupon.swift
//  cuponeame
//
//  Created by Blue on 25/8/23.
//

import Foundation

/*
class CouponModel: Identifiable, ObservableObject {
    var id: String
    var title: String
    var category: String
    var description: String
    var short_description: String
    var imageName: String
    var used: Bool
    var cooldownTime: TimeInterval?
    var cooldownExpirationDate: Date?
    var redeemCount: Int
    var redeemLimit: Int
}

extension CouponModel {
    mutating func redeem() {
        if redeemCount < redeemLimit {
            self.used = true

            if let cooldown = cooldownTime {
                self.cooldownExpirationDate = Date().addingTimeInterval(cooldown)
            }

            self.redeemCount += 1
        } else {
            print("El cupón ha alcanzado su límite de canjes.")
        }
    }

    mutating func isAvailable() -> Bool {
        guard let expirationDate = cooldownExpirationDate else { return true }
        let isPastExpiration = Date() > expirationDate
        if isPastExpiration {
            self.used = false
        }
        return isPastExpiration
    }
}
*/

class CouponModel: Identifiable, ObservableObject {
    var id: String
    var title: String
    var category: String
    var description: String
    var short_description: String
    var imageName: String
    @Published var used: Bool
    @Published var cooldownTime: TimeInterval?
    @Published var cooldownExpirationDate: Date?
    @Published var redeemCount: Int
    var redeemLimit: Int
    
    init(id: String, title: String, category: String, description: String, short_description: String, imageName: String, used: Bool, cooldownTime: TimeInterval?, cooldownExpirationDate: Date?, redeemCount: Int, redeemLimit: Int) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.short_description = short_description
        self.imageName = imageName
        self.used = used
        self.cooldownTime = cooldownTime
        self.cooldownExpirationDate = cooldownExpirationDate
        self.redeemCount = redeemCount
        self.redeemLimit = redeemLimit
    }
    
    func redeem() {
        if redeemCount < redeemLimit {
            self.used = true

            if let cooldown = cooldownTime {
                self.cooldownExpirationDate = Date().addingTimeInterval(cooldown)
            }

            self.redeemCount += 1
        } else {
            print("El cupón ha alcanzado su límite de canjes.")
        }
    }
    
    func isAvailable() -> Bool {
        guard let expirationDate = cooldownExpirationDate else { return true }
        let isPastExpiration = Date() > expirationDate
        if isPastExpiration {
            self.used = false
        }
        return isPastExpiration
    }
}

