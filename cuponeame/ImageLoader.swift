//
//  ImageLoader.swift
//  cuponeame
//
//  Created by Blue on 14/10/23.
//

import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?

    func load(from url: URL) {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }

    deinit {
        cancellable?.cancel()
    }
}

struct FirebaseImageView: View {
    @StateObject private var loader = ImageLoader()
    let placeholder: Image
    let url: URL

    init(url: URL, placeholder: Image = Image("placeholder")) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        if let image = loader.image {
            Image(uiImage: image)
                .resizable()
        } else {
            placeholder
                .onAppear {
                    loader.load(from: url)
                }
        }
    }
}
