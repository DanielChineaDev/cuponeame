//
//  ImageLoader.swift
//  cuponeame
//
//  Created by Blue on 14/10/23.
//

import SwiftUI
import Firebase
import FirebaseStorage

class ImageLoader: ObservableObject {
    @Published var image: Image?
    
    func downloadImageFromFirebase(imageName: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child(imageName)
        
        imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error al descargar imagen: \(error.localizedDescription)")
            } else {
                if let imageData = data, let uiImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.image = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}


