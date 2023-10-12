//
//  AuthViewModel.swift
//  cuponeame
//
//  Created by Blue on 31/8/23.
//

import Firebase
import FirebaseFirestore
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    
    @Published var user: User?
    @Published var userUID: String?

    let couponViewModel = CouponViewModel()

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                self?.user = user
                self?.couponViewModel.loadUserCoupons(userID: user.uid)
                self?.userUID = user.uid
                
            } else if let error = error {
                print("Error al iniciar sesión:", error.localizedDescription)
            }
        }
    }

    func signUp(email: String, password: String, name: String){
        let db = Firestore.firestore()
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                self?.user = user

                db.collection("users").document(user.uid).setData([
                    "name": name,
                    "email": email
                ]) { error in
                    if let error = error {
                        print("Error al crear el documento del usuario: \(error)")

                    } else {
                        // Añadir los cupones predeterminados
                        self?.couponViewModel.addDefaultCouponsToUser(userID: user.uid)
                        self?.couponViewModel.loadUserCoupons(userID: user.uid)
                    }
                }
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        user = nil
    }

    func currentUser() -> String{
//        user = Auth.auth().currentUser
        return user?.email ?? "Sin mail"
    }
}
