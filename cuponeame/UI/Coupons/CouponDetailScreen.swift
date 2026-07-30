import SwiftUI

/// Detalle de un cupón: foto con chips, código de barras y botón de canjeo
/// con cuenta atrás en vivo. Observa el store, así que cualquier cambio en
/// Firestore (canjeo, edición) se refleja al momento.
struct CouponDetailScreen: View {
    let couponID: String

    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showRedeemConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    var body: some View {
        if let coupon = store.coupon(id: couponID) {
            content(for: coupon)
        } else {
            // El cupón se acaba de eliminar: no queda nada que mostrar.
            Color.clear.onAppear { dismiss() }
        }
    }

    private func content(for coupon: Coupon) -> some View {
        VStack(spacing: 16) {
            photoCard(for: coupon)

            redeemButton(for: coupon)
        }
        .padding(16)
        .background(CuponColors.background)
        .navigationTitle("Detalle de cupón")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await store.toggleFavorite(coupon) }
                } label: {
                    Image(systemName: coupon.favorite ? "heart.fill" : "heart")
                        .foregroundStyle(CuponColors.brandPink)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText(for: coupon)) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                CouponFormScreen(mode: .edit(coupon))
            }
        }
        .alert("¿Canjear este cupón?", isPresented: $showRedeemConfirmation) {
            Button("Canjear") {
                Task { await store.redeem(coupon) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(redeemMessage(for: coupon))
        }
        .alert("¿Eliminar \"\(coupon.title)\"?", isPresented: $showDeleteConfirmation) {
            Button("Eliminar", role: .destructive) {
                Task {
                    await store.delete(coupon)
                    dismiss()
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }

    // MARK: - Foto con chips

    private func photoCard(for coupon: Coupon) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text(coupon.title)
                    .font(.title.bold())
                    .chip()

                Spacer()

                Text("\(coupon.redeemCount)/\(coupon.redeemLimit)")
                    .font(.headline)
                    .chip()
            }

            Label(coupon.category, systemImage: coupon.categoryIcon)
                .font(.subheadline)
                .chip()

            Spacer()

            Text(coupon.description)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .chip()

            barcodeCard(for: coupon)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            CouponImageView(path: coupon.imageName)
                .grayscale(coupon.isExhausted ? 1 : 0))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    private func barcodeCard(for coupon: Coupon) -> some View {
        VStack(spacing: 6) {
            Image("barcode")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: 50)

            Text(coupon.barcode)
                .font(.callout.monospaced())
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .foregroundStyle(.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 5)
    }

    // MARK: - Canjeo

    private func redeemButton(for coupon: Coupon) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            Button {
                showRedeemConfirmation = true
            } label: {
                Group {
                    if coupon.isExhausted {
                        Text("LÍMITE DE USOS ALCANZADO")
                    } else if coupon.isOnCooldown(now: now) {
                        Label(coupon.remainingCooldownText(now: now), systemImage: "clock.fill")
                            .monospacedDigit()
                    } else {
                        Text("CANJEAR")
                    }
                }
                .font(.headline)
            }
            .buttonStyle(BrandButtonStyle())
            .disabled(!coupon.canRedeem(now: now))
            .opacity(coupon.canRedeem(now: now) ? 1 : 0.55)
        }
    }

    private func redeemMessage(for coupon: Coupon) -> String {
        var parts = ["Quedan \(coupon.redeemLimit - coupon.redeemCount) usos."]
        if let cooldown = coupon.cooldownTime, cooldown > 0 {
            parts.append("Después habrá que esperar para volver a usarlo.")
        }
        return parts.joined(separator: " ")
    }

    private func shareText(for coupon: Coupon) -> String {
        """
        🎟️ Cupón: \(coupon.title)
        \(coupon.shortDescription)
        — Enviado con Cuponéame 💜
        """
    }
}

private extension View {
    func chip() -> some View {
        self
            .padding(8)
            .background(Color.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.black)
    }
}
