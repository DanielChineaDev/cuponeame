import SwiftUI
import PhotosUI

/// Formulario de cupón, para crear (pestaña Crear) y editar (hoja del detalle).
struct CouponFormScreen: View {
    enum Mode: Equatable {
        case create
        case edit(Coupon)
    }

    let mode: Mode
    /// Idea con la que arrancar el formulario (desde el hub de Crear).
    var template: CouponTemplate?
    /// Arrancar con el destinatario en "pareja" (botón «Regalar» del hub).
    var startGifting = false

    @Environment(AuthService.self) private var auth
    @Environment(CouponStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var shortDescription = ""
    @State private var longDescription = ""
    @State private var category: CouponCategory = .romance
    @State private var imageName = DefaultCoupons.imageOptions[0]
    @State private var cooldown: TimeInterval? = 10800
    @State private var redeemLimit = 5

    @State private var photoItem: PhotosPickerItem?
    @State private var customPhoto: UIImage?
    @State private var giftToPartner = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var didPrefill = false

    // Diálogos posteriores a crear (solo modo crear, no regalo directo).
    @State private var showGiftedConfirm = false
    @State private var showOfferGift = false
    @State private var showNoPartnerHint = false
    @State private var createdCoupon: Coupon?

    /// Presets de tiempo de espera entre canjeos.
    private static let cooldownOptions: [(label: String, value: TimeInterval?)] = [
        ("Sin espera", nil),
        ("30 minutos", 1800),
        ("1 hora", 3600),
        ("2 horas", 7200),
        ("3 horas", 10800),
        ("12 horas", 43200),
        ("1 día", 86400),
        ("2 días", 172800),
        ("1 semana", 604800),
    ]

    private var isEditing: Bool { mode != .create }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    /// El ticket tal y como quedará: se pinta arriba y se refresca al escribir.
    private var previewCoupon: Coupon {
        Coupon(title: title.isEmpty ? "Tu cupón" : title,
               category: category.rawValue,
               description: longDescription,
               shortDescription: shortDescription.isEmpty
                   ? "Así se verá en tu talonario." : shortDescription,
               imageName: imageName,
               cooldownTime: cooldown,
               redeemLimit: redeemLimit)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("VISTA PREVIA")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(CuponColors.subtleText)
                        .padding(.leading, 6)

                    CouponCard(coupon: previewCoupon, previewImage: customPhoto)
                        .allowsHitTesting(false)
                        .animation(.snappy, value: imageName)
                }

                if let partnerName = auth.partnerName, !isEditing {
                    SectionCard("Destinatario") {
                        Picker("Para", selection: $giftToPartner) {
                            Text("Para mí").tag(false)
                            Text("Para \(partnerName)").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                SectionCard("Cupón") {
                    AuthField(icon: "textformat") {
                        TextField("Título", text: $title)
                    }
                    AuthField(icon: "text.quote") {
                        TextField("Descripción corta", text: $shortDescription)
                    }
                    AuthField(icon: "text.alignleft") {
                        TextField("Descripción", text: $longDescription, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }

                SectionCard("Categoría") {
                    categoryChips
                }

                SectionCard("Imagen") {
                    imageGallery
                    if store.isDemo {
                        Label("Las fotos propias necesitan una cuenta", systemImage: "photo.on.rectangle.angled")
                            .foregroundStyle(CuponColors.subtleText)
                    } else {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(customPhoto == nil ? "Usar una foto propia" : "Cambiar la foto propia",
                                  systemImage: "photo.on.rectangle.angled")
                                .foregroundStyle(CuponColors.brandPurple)
                        }
                    }
                }

                SectionCard("Reglas") {
                    HStack {
                        Label("Tiempo de espera", systemImage: "clock.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Picker("", selection: $cooldown) {
                            ForEach(Self.cooldownOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(CuponColors.brandPurple)
                    }

                    Divider()

                    Stepper(value: $redeemLimit, in: 1...50) {
                        Label("Límite de canjes: **\(redeemLimit)**", systemImage: "checkmark.seal.fill")
                    }
                }

                if let saveError {
                    Label(saveError, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else if isEditing {
                        Text("GUARDAR CAMBIOS")
                    } else if giftToPartner, let partnerName = auth.partnerName {
                        Label("ENVIAR A \(partnerName.uppercased())", systemImage: "gift.fill")
                    } else {
                        Text("CREAR CUPÓN")
                    }
                }
                .buttonStyle(BrandButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)
            }
            .padding(16)
        }
        .background(CuponColors.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isEditing ? "Editar cupón" : "Nuevo cupón")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .onAppear(perform: loadIfEditing)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    customPhoto = image
                }
            }
        }
        .alert("¡Cupón enviado a \(auth.partnerName ?? "tu pareja")!", isPresented: $showGiftedConfirm) {
            Button("Genial") { dismiss() }
        } message: {
            Text("Ya lo tiene en su talonario.")
        }
        .alert("¡Cupón creado!", isPresented: $showOfferGift) {
            Button("Regalárselo a \(auth.partnerName ?? "mi pareja")") {
                Task {
                    if let createdCoupon, let partnerUID = auth.partnerUID {
                        await store.gift(createdCoupon, to: partnerUID, from: auth.userName ?? "Tu pareja")
                    }
                    dismiss()
                }
            }
            Button("Ahora no", role: .cancel) { dismiss() }
        } message: {
            Text("Ya está en tu talonario. ¿Se lo regalas también a \(auth.partnerName ?? "tu pareja")?")
        }
        .alert("¡Cupón creado!", isPresented: $showNoPartnerHint) {
            Button("Entendido") { dismiss() }
        } message: {
            Text("Ya está en tu talonario. Si vinculas tu cuenta con tu pareja en Ajustes, podrás enviárselo con un toque.")
        }
    }

    // MARK: - Categoría

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CouponCategory.allCases) { option in
                    let selected = category == option
                    Button {
                        withAnimation(.snappy) { category = option }
                    } label: {
                        Label(option.rawValue, systemImage: option.icon)
                            .font(.subheadline.weight(selected ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(selected ? .white : .primary)
                            .background {
                                if selected {
                                    Capsule().fill(CuponColors.brandStroke)
                                } else {
                                    Capsule().fill(CuponColors.background)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Galería

    private var imageGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let customPhoto {
                    thumbnail(image: Image(uiImage: customPhoto), selected: true)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                self.customPhoto = nil
                                photoItem = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .black.opacity(0.6))
                                    .padding(4)
                            }
                        }
                }
                ForEach(DefaultCoupons.imageOptions, id: \.self) { option in
                    if let name = ImageService.bundledName(for: option) {
                        Button {
                            imageName = option
                            customPhoto = nil
                            photoItem = nil
                        } label: {
                            thumbnail(image: Image(name),
                                      selected: customPhoto == nil && imageName == option)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func thumbnail(image: Image, selected: Bool) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? CuponColors.brandStroke
                                     : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 3))
    }

    // MARK: - Guardado

    private func loadIfEditing() {
        guard !didPrefill else { return }
        didPrefill = true

        if startGifting, auth.partnerName != nil {
            giftToPartner = true
        }

        if case .edit(let coupon) = mode {
            title = coupon.title
            shortDescription = coupon.shortDescription
            longDescription = coupon.description
            category = CouponCategory(rawValue: coupon.category) ?? .personalizado
            imageName = coupon.imageName
            // Cooldowns legacy que no coinciden con ningún preset: al más cercano,
            // para que el picker no se quede sin selección.
            if let current = coupon.cooldownTime {
                cooldown = Self.cooldownOptions.compactMap(\.value)
                    .min { abs($0 - current) < abs($1 - current) }
            } else {
                cooldown = nil
            }
            redeemLimit = coupon.redeemLimit
        } else if let template {
            title = template.title
            shortDescription = template.shortDescription
            longDescription = template.description
            category = template.category
            imageName = template.imageName
            cooldown = template.cooldown
        }
    }

    private func save() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        var finalImageName = imageName
        if let customPhoto {
            guard let uid = auth.user?.uid else {
                saveError = "Las fotos propias necesitan una cuenta."
                return
            }
            do {
                finalImageName = try await ImageService.shared.uploadCouponImage(customPhoto, uid: uid)
            } catch {
                saveError = "No se pudo subir la foto. Inténtalo de nuevo."
                return
            }
        }

        switch mode {
        case .create:
            let coupon = Coupon(
                title: title,
                category: category.rawValue,
                description: longDescription,
                shortDescription: shortDescription,
                imageName: finalImageName,
                cooldownTime: cooldown,
                redeemLimit: redeemLimit)
            if giftToPartner, let partnerUID = auth.partnerUID {
                guard await store.gift(coupon, to: partnerUID,
                                       from: auth.userName ?? "Tu pareja") else { return }
                showGiftedConfirm = true
            } else {
                await store.save(coupon)
                // Tras crearlo para mí: ofrecer regalarlo si hay pareja, o
                // sugerir vincularse si aún no lo está.
                if auth.partnerName != nil {
                    createdCoupon = coupon
                    showOfferGift = true
                } else {
                    showNoPartnerHint = true
                }
            }

        case .edit(let original):
            var updated = original
            updated.title = title
            updated.category = category.rawValue
            updated.description = longDescription
            updated.shortDescription = shortDescription
            updated.imageName = finalImageName
            updated.cooldownTime = cooldown
            updated.redeemLimit = redeemLimit
            await store.save(updated)
            dismiss()
        }
    }
}
