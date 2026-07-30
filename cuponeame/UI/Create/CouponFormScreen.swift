import SwiftUI
import PhotosUI

/// Formulario de cupón, para crear (pestaña Crear) y editar (hoja del detalle).
struct CouponFormScreen: View {
    enum Mode: Equatable {
        case create
        case edit(Coupon)
    }

    let mode: Mode

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
    @State private var showSaved = false
    @State private var savedMessage = ""
    @State private var saveError: String?

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

    var body: some View {
        Form {
            if let partnerName = auth.partnerName, !isEditing {
                Section("Destinatario") {
                    Picker("Para", selection: $giftToPartner) {
                        Text("Para mí").tag(false)
                        Text("Para \(partnerName) 💝").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Cupón") {
                TextField("Título", text: $title)
                TextField("Descripción corta", text: $shortDescription)
                TextField("Descripción", text: $longDescription, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Categoría") {
                Picker("Categoría", selection: $category) {
                    ForEach(CouponCategory.allCases) { option in
                        Label(option.rawValue, systemImage: option.icon)
                            .tag(option)
                    }
                }
            }

            Section("Imagen") {
                imageGallery
                if store.isDemo {
                    Label("Las fotos propias necesitan una cuenta", systemImage: "photo.on.rectangle.angled")
                        .foregroundStyle(CuponColors.subtleText)
                } else {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(customPhoto == nil ? "Usar una foto propia" : "Cambiar la foto propia",
                              systemImage: "photo.on.rectangle.angled")
                    }
                }
            }

            Section("Reglas") {
                Picker("Tiempo de espera", selection: $cooldown) {
                    ForEach(Self.cooldownOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                Stepper("Límite de canjes: \(redeemLimit)", value: $redeemLimit, in: 1...50)
            }

            if let saveError {
                Section {
                    Text(saveError).foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if isEditing {
                        Text("GUARDAR CAMBIOS")
                    } else if giftToPartner, let partnerName = auth.partnerName {
                        Text("ENVIAR A \(partnerName.uppercased()) 🎁")
                    } else {
                        Text("CREAR CUPÓN")
                    }
                }
                .buttonStyle(BrandButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .navigationTitle(isEditing ? "Editar cupón" : "Nuevo cupón")
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
        .alert(savedMessage, isPresented: $showSaved) {
            Button("Genial") {}
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
        guard case .edit(let coupon) = mode, title.isEmpty else { return }
        title = coupon.title
        shortDescription = coupon.shortDescription
        longDescription = coupon.description
        category = CouponCategory(rawValue: coupon.category) ?? .personalizado
        imageName = coupon.imageName
        cooldown = coupon.cooldownTime
        redeemLimit = coupon.redeemLimit
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
                savedMessage = "¡Cupón enviado a \(auth.partnerName ?? "tu pareja")! 🎁"
            } else {
                await store.save(coupon)
                savedMessage = "¡Cupón creado! Ya está en tu lista."
            }
            resetForm()
            showSaved = true

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

    private func resetForm() {
        title = ""
        shortDescription = ""
        longDescription = ""
        category = .romance
        imageName = DefaultCoupons.imageOptions[0]
        cooldown = 10800
        redeemLimit = 5
        customPhoto = nil
        photoItem = nil
        giftToPartner = false
    }
}
