//
//  AuthViewModel.swift
//  cuponeame
//
//  Created by Blue on 31/8/23.
//

import Firebase
import FirebaseFirestore
import FirebaseStorage
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    
    @Published var user: User?
    @Published var userUID: String?
    @Published var userName: String? = nil
    @Published var hasFetchedUserName = false

    let couponViewModel = CouponViewModel()
    let storage = Storage.storage()

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


    func currentUserName() {
        guard !hasFetchedUserName else { return }

        guard let userId = Auth.auth().currentUser?.uid else {
            self.userName = "Sin nombre"
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.userName = document.data()?["name"] as? String ?? "Sin nombre"
                self.hasFetchedUserName = true
            } else {
                print("Error obteniendo el nombre: \(error?.localizedDescription ?? "Error desconocido")")
                self.userName = "Sin nombre"
            }
        }
    }
    
    func getDownloadableURL(forPath path: String, completion: @escaping (URL?, Error?) -> Void) {
        let reference = storage.reference().child(path)
        
        reference.downloadURL { (url, error) in
            completion(url, error)
        }
    }
}
