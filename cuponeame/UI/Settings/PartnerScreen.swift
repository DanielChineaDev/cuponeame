import SwiftUI

/// Modo pareja: vincular dos cuentas con un código de invitación para
/// regalarse cupones el uno al otro.
struct PartnerScreen: View {
    @Environment(AuthService.self) private var auth

    @State private var generatedCode: String?
    @State private var enteredCode = ""
    @State private var showUnlinkConfirmation = false
    @State private var justLinked = false
    @State private var copied = false

    var body: some View {
        Form {
            if let partner = auth.partnerName {
                linkedContent(partner: partner)
            } else {
                unlinkedContent
            }

            if let message = auth.errorMessage {
                Section {
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Modo pareja")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { auth.errorMessage = nil }
        .alert("¡Vinculados! 💜", isPresented: $justLinked) {
            Button("Genial") {}
        } message: {
            Text("Ya podéis regalaros cupones el uno al otro desde la pestaña Crear.")
        }
        .alert("¿Desvincular a \(auth.partnerName ?? "tu pareja")?", isPresented: $showUnlinkConfirmation) {
            Button("Desvincular", role: .destructive) {
                Task { await auth.unlinkPartner() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El vínculo se rompe en las dos cuentas. Los cupones ya regalados se quedan donde están.")
        }
    }

    // MARK: - Sin vincular

    @ViewBuilder
    private var unlinkedContent: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(CuponColors.brandStroke)
                Text("Vincula tu cuenta con la de tu pareja para regalaros cupones el uno al otro.")
                    .multilineTextAlignment(.center)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }

        Section {
            if let code = generatedCode {
                VStack(spacing: 10) {
                    Text(code)
                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                        .tracking(6)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(CuponColors.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(CuponColors.brandStroke, lineWidth: 2))

                    HStack {
                        Button {
                            UIPasteboard.general.string = code
                            copied = true
                        } label: {
                            Label(copied ? "¡Copiado!" : "Copiar", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)

                        ShareLink(item: shareMessage(code: code)) {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                Button {
                    Task {
                        generatedCode = await auth.createInviteCode()
                        copied = false
                    }
                } label: {
                    if auth.isWorking {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label("Crear código de invitación", systemImage: "wand.and.stars")
                    }
                }
            }
        } header: {
            Text("Invita a tu pareja")
        } footer: {
            Text("Pásale el código: cuando lo introduzca en su app, quedaréis vinculados.")
        }

        Section {
            HStack {
                TextField("CÓDIGO", text: $enteredCode)
                    .font(.body.monospaced())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: enteredCode) { _, newValue in
                        enteredCode = InviteCode.normalized(newValue)
                    }

                Button("Vincular") {
                    Task {
                        if await auth.redeemInviteCode(enteredCode) {
                            enteredCode = ""
                            justLinked = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(CuponColors.brandPink)
                .disabled(enteredCode.count < InviteCode.length || auth.isWorking)
            }
        } header: {
            Text("¿Te han pasado un código?")
        }
    }

    // MARK: - Vinculado

    @ViewBuilder
    private func linkedContent(partner: String) -> some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(CuponColors.brandStroke)
                Text("Vinculado con **\(partner)** 💜")
                    .font(.title3)
                Text("Crea un cupón en la pestaña Crear y elige \"Para \(partner)\" para regalárselo, o usa \"Regalar\" en el detalle de cualquier cupón.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(CuponColors.subtleText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }

        Section {
            Button("Desvincular", role: .destructive) {
                showUnlinkConfirmation = true
            }
        }
    }

    private func shareMessage(code: String) -> String {
        """
        💜 Vincúlate conmigo en Cuponéame para regalarnos cupones.
        Mi código de invitación es: \(code)
        """
    }
}
