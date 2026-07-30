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
    @State private var showGifted = false

    var body: some View {
        if let coupon = store.coupon(id: couponID) {
            content(for: coupon)
        } else {
            // El cupón se acaba de eliminar: no queda nada que mostrar.
            Color.clear.onAppear { dismiss() }
        }
    }

    private func content(for coupon: Coupon) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                ticket(for: coupon)
                    .padding(16)
            }
            .scrollBounceBehavior(.basedOnSize)

            redeemButton(for: coupon)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
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
                    if let partnerName = auth.partnerName, let partnerUID = auth.partnerUID {
                        Button {
                            Task {
                                if await store.gift(coupon, to: partnerUID,
                                                    from: auth.userName ?? "Tu pareja") {
                                    showGifted = true
                                }
                            }
                        } label: {
                            Label("Regalar a \(partnerName)", systemImage: "gift")
                        }
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
        .alert("¡Cupón enviado! 🎁", isPresented: $showGifted) {
            Button("Genial") {}
        } message: {
            Text("\(auth.partnerName ?? "Tu pareja") ya lo tiene en su talonario.")
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

    // MARK: - Ticket

    private static let photoHeight: CGFloat = 260

    private func ticket(for coupon: Coupon) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: Self.photoHeight)
                .frame(maxWidth: .infinity)
                .overlay(
                    CouponImageView(path: coupon.imageName)
                        .grayscale(coupon.isExhausted ? 1 : 0))
                .clipped()
                .overlay(alignment: .topLeading) {
                    statusChip(for: coupon).padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    usesBadge(for: coupon).padding(12)
                }

            VStack(alignment: .leading, spacing: 12) {
                Text(coupon.title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))

                HStack(spacing: 12) {
                    Label(coupon.category, systemImage: coupon.categoryIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CuponColors.brandPurple)

                    if let from = coupon.from {
                        Label("De \(from)", systemImage: "gift.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CuponColors.brandPink)
                    }
                }

                let text = coupon.description.isEmpty ? coupon.shortDescription : coupon.description
                if !text.isEmpty {
                    Text(text)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                dashedSeparator
                    .padding(.top, 4)

                barcodeSticker(for: coupon)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(CuponColors.surface)
        .clipShape(PunchedTicketShape(notchY: Self.photoHeight, cornerRadius: 24, notchRadius: 12),
                   style: FillStyle(eoFill: true))
        .overlay(TicketPerforation(y: Self.photoHeight))
        .compositingGroup()
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }

    @ViewBuilder
    private func statusChip(for coupon: Coupon) -> some View {
        if coupon.isExhausted {
            photoChip("Agotado", icon: "nosign")
        } else if coupon.isOnCooldown() {
            photoChip("En espera", icon: "clock.fill")
        }
    }

    private func photoChip(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .cuponGlassCapsuleTinted(.black.opacity(0.45))
    }

    private func usesBadge(for coupon: Coupon) -> some View {
        Label("\(coupon.redeemCount)/\(coupon.redeemLimit)", systemImage: "checkmark.seal.fill")
            .font(.subheadline.bold())
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .cuponGlassCapsuleTinted(.black.opacity(0.45))
    }

    private var dashedSeparator: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: proxy.size.width, y: 0))
            }
            .stroke(CuponColors.subtleText.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        }
        .frame(height: 1)
    }

    private func barcodeSticker(for coupon: Coupon) -> some View {
        VStack(spacing: 6) {
            Image("barcode")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: 50)

            Text(coupon.barcode)
                .font(.callout.monospaced())
                .foregroundStyle(.black)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CuponColors.subtleText.opacity(0.2), lineWidth: 1))
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
