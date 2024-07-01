import SwiftUI
import Kingfisher

extension View {
    func commonToolbar(authViewModel: AuthViewModel, imageURL: Binding<URL?>, isProfileSheetPresented: Binding<Bool>) -> some View {
        
        self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isProfileSheetPresented.wrappedValue.toggle()

                }) {
                    HStack(spacing: 8) {
                        Text(authViewModel.userName ?? "")

                        KFImage(imageURL.wrappedValue)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 0)
                            )
                            
                        }
                }
                .sheet(isPresented: isProfileSheetPresented) {
                    ProfileView(authViewModel: authViewModel, imageURL: imageURL, isProfileSheetPresented: isProfileSheetPresented)
                        .environmentObject(authViewModel)
                }

                .onAppear {
                    authViewModel.currentUserName()
                    authViewModel.getDownloadableURL(forPath: "/defaults-avatars/pingu-avatar.jpg") { (url, error) in
                        if let error = error {
                            print("Error obteniendo la URL: \(error.localizedDescription)")
                        } else if let url = url {
                            imageURL.wrappedValue = url
                        }
                    }
                }

            }
        }
    }
}
