<div align="center">

<img src="cuponeame/Resources/Assets.xcassets/logo.imageset/logo.png" width="160" alt="Cuponéame" />

# Cuponéame

**Cupones para regalar momentos a quien más quieres.**

App iOS nativa de cupones canjeables entre parejas: crea cupones personalizados con foto, canjéalos con tiempo de espera y límite de usos, y guarda cada momento en el historial. Estética *Liquid Glass* de iOS 26 sobre el gradiente morado→rosa de la marca.

![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.10-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0071E3?logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-26-1575F9?logo=xcode&logoColor=white)
![Firebase](https://img.shields.io/badge/Backend-Firebase%2012-FFCA28?logo=firebase&logoColor=black)
![Tests](https://img.shields.io/badge/tests-27%20%E2%9C%93-brightgreen)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

</div>

---

## 📸 Capturas

<div align="center">

| Bienvenida | Lista | Detalle |
|:---:|:---:|:---:|
| <img src="docs/capturas/bienvenida.png" width="230" /> | <img src="docs/capturas/lista.png" width="230" /> | <img src="docs/capturas/detalle.png" width="230" /> |
| **Crear** | **Modo pareja** | **Historial** |
| <img src="docs/capturas/crear.png" width="230" /> | <img src="docs/capturas/pareja.png" width="230" /> | <img src="docs/capturas/historial.png" width="230" /> |

<sub>Gradiente morado→rosa + Liquid Glass + tarjetas foto-a-sangre: el lenguaje visual de Cuponéame.</sub>

</div>

---

## ✨ Características

- 💑 **Modo pareja**: vincula dos cuentas con un **código de invitación** (6 caracteres, compartible por cualquier app) y **regalaos cupones** el uno al otro — desde Crear ("Para X 💝") o desde el detalle ("Regalar a X"). Los regalos llegan firmados con el chip "De X".
- 🎟️ **Cupones canjeables** con foto a sangre, chips blancos y anillo de usos restantes.
- ⏳ **Tiempo de espera real** entre canjeos, con cuenta atrás en vivo sobre el botón de canjear.
- 🧮 **Límite de usos** por cupón; al agotarse, la tarjeta pasa a escala de grises.
- ➕ **Crear y editar cupones**: galería del catálogo o **foto propia** (PhotosPicker → Firebase Storage, reescalada).
- ❤️ **Favoritos** y **filtros** por categoría con chips de cristal, más **buscador**.
- 📜 **Historial de canjes** agrupado por día (Hoy / Ayer / fecha).
- 📤 **Compartir** cupones por cualquier app (ShareLink).
- 🔐 **Cuenta con Firebase Auth**: sesión persistente, recuperar/cambiar contraseña, cambiar nombre y **eliminar cuenta** (requisito App Store).
- ⚙️ **Ajustes completos**: resumen con contadores, tema Sistema/Claro/Oscuro, compartir la app y enviar sugerencias.
- 🎁 **Pack de ejemplo**: 11 cupones para estrenar la cuenta (o restaurarlos desde Ajustes).
- 👤 **Modo demo** ("Probar sin cuenta"): toda la app funciona con datos locales en memoria — ideal para probarla y para la review de la App Store.
- 🧊 **Liquid Glass iOS 26** con fallback a materiales en iOS 17-25; modo claro y oscuro.
- 📶 Las imágenes del catálogo son locales: la lista funciona **sin conexión**.

---

## 🏗️ Arquitectura

MVVM ligero con inyección por entorno (patrón GasApp): la UI observa *stores* `@Observable`; los *stores* escuchan Firestore con listeners en vivo, así que cualquier cambio (propio o desde otro dispositivo) refresca la interfaz al momento.

```mermaid
flowchart TD
    subgraph UI["🎨 UI · SwiftUI"]
        V["Bienvenida · Lista · Detalle<br/>Crear · Ajustes (Liquid Glass)"]
    end
    subgraph STORE["🧠 Estado · @Observable"]
        S1["AuthService"]
        S2["CouponStore"]
        S3["ImageService"]
    end
    subgraph DATA["💾 Firebase"]
        D1["Auth<br/>(sesión)"]
        D2["Firestore<br/>users/{uid}/coupons<br/>users/{uid}/redemptions"]
        D3["Storage<br/>fotos propias + caché de URLs"]
    end

    V --> S1 & S2 & S3
    S1 --> D1 & D2
    S2 -->|listeners en vivo| D2
    S3 --> D3
```

### Estructura

```
cuponeame/
├── App/            # Entrada, FirebaseApp.configure() antes que los stores
├── Data/           # AuthService · CouponStore · ImageService
├── Shared/Models/  # Coupon · Redemption · DefaultCoupons (contrato Firestore)
├── UI/
│   ├── Theme/      # Paleta + gradiente de marca · helpers Liquid Glass
│   ├── Auth/       # Bienvenida · Login · Registro
│   ├── Coupons/    # Lista · Tarjeta · Detalle
│   ├── Create/     # Formulario crear/editar
│   └── Settings/   # Ajustes · Historial
└── Resources/      # Assets (fotos del catálogo en local)
```

### Contratos compartidos

> ⚠️ No cambiar sin migración: rompen los datos de cuentas existentes.

| Contrato | Valor |
|---|---|
| Campos Firestore de cupón | `title`, `category`, `description`, `short_description`, `imageName`, `used`, `cooldownTime`, `cooldownExpirationDate`, `redeemCount`, `redeemLimit` (+ nuevos `favorite`, `createdAt`, `from`) |
| Perfil `users/{uid}` | `name`, `email` (+ modo pareja: `partnerUID`, `partnerName`) |
| Invitaciones | `invites/{code}` → `ownerUID`, `ownerName`, `createdAt`; el código se consume al vincular |
| Rutas de imágenes del catálogo | `/defaults-coupons/*.jpg` (con espejo local en Assets) |
| Fotos propias | `user-images/{uid}/{uuid}.jpg` en Storage |

---

## 🚀 Puesta en marcha

```bash
brew install xcodegen
git clone git@github.com:DanielChineaDev/cuponeame.git && cd cuponeame
# Descargar GoogleService-Info.plist del proyecto Firebase "cuponeame-372cb"
# y colocarlo en cuponeame/Configurations/
xcodegen generate
open Cuponeame.xcodeproj
```

Los tests: esquema **Cuponeame** → ⌘U (27 tests: modelo, contrato Firestore, códigos de invitación y modo demo).

---

## 🗺️ Roadmap

- [x] Migración a XcodeGen + Firebase 12 + Liquid Glass
- [x] Crear/editar cupones con foto propia
- [x] Favoritos, filtros, buscador e historial
- [x] Modo demo para probar la app sin cuenta
- [x] **Modo pareja**: código de invitación, cuentas vinculadas y regalos de cupones
- [ ] Notificación push cuando tu pareja canjea o te regala un cupón
- [ ] Avatares personalizables (hoy: pingüino para todo el mundo 🐧)
- [ ] Widget con el próximo cupón disponible
- [ ] Reglas de seguridad de Firestore por usuario + App Check

---

<div align="center">
<sub>Hecho con 💜 por <b>BPO Studios</b></sub>
</div>
