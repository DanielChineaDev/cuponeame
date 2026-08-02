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
![Tests](https://img.shields.io/badge/tests-31%20%E2%9C%93-brightgreen)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

</div>

---

## 📸 Capturas

<div align="center">

| Bienvenida | Lista | Detalle |
|:---:|:---:|:---:|
| <img src="docs/capturas/bienvenida.png" width="230" /> | <img src="docs/capturas/lista.png" width="230" /> | <img src="docs/capturas/detalle.png" width="230" /> |
| **Crear** | **Ajustes** | **Historial** |
| <img src="docs/capturas/crear.png" width="230" /> | <img src="docs/capturas/ajustes.png" width="230" /> | <img src="docs/capturas/historial.png" width="230" /> |

<sub>Gradiente morado→rosa + Liquid Glass + tarjetas foto-a-sangre: el lenguaje visual de Cuponéame.</sub>

| Login | Registro |
|:---:|:---:|
| <img src="docs/capturas/login.png" width="230" /> | <img src="docs/capturas/registro.png" width="230" /> |
| **Modo pareja** | **Modo oscuro** |
| <img src="docs/capturas/pareja.png" width="230" /> | <img src="docs/capturas/oscuro.png" width="230" /> |
| **Widget** | **Perfil** |
| <img src="docs/capturas/widget.png" width="230" /> | <img src="docs/capturas/perfil.png" width="230" /> |

<sub>Identidad rediseñada: logo vectorial de ticket (el mismo del AppIcon), tema Sistema/Claro/Oscuro y widget «Próximo cupón».</sub>

</div>

---

## ✨ Características

- 💑 **Modo pareja**: vincula dos cuentas con un **código de invitación** (6 caracteres, compartible por cualquier app) y **regalaos cupones** el uno al otro — desde Crear ("Para X 💝") o desde el detalle ("Regalar a X"). Los regalos llegan firmados con el chip "De X" y disparan el aviso **"💝 ¡Regalo de X!"** en vivo gracias a los listeners.
- 🧩 **Widget** "Próximo cupón" (WidgetKit small/medium): el siguiente cupón canjeable y el contador de disponibles, alimentado por un snapshot en el App Group — sin tocar Firebase desde el widget.
- 🧑‍🎨 **Avatares personalizables**: 20 emojis sobre gradiente de marca (o el pingu clásico), sincronizados en el perfil.
- 💎 **Monetización**: intersticial cada 3 cupones abiertos, **5 creaciones al mes** recargables con un **anuncio bonificado** (+3), y **Premium** de pago único (StoreKit 2) que quita los anuncios y da **cupones ilimitados**.
- 👤 **Perfil de usuario** (tocando tu avatar en Cupones): tus datos, resumen y **con quién estás conectado** — los dos avatares unidos por un corazón, con acceso directo a gestionar el vínculo o vincularte si aún no lo estás.
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
| Perfil `users/{uid}` | `name`, `email`, `avatar` (emoji) (+ modo pareja: `partnerUID`, `partnerName`) |
| Widget | Snapshot JSON en App Group `group.com.bpo.cuponeame`, clave `widget-snapshot` |
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

Los tests: esquema **Cuponeame** → ⌘U (31 tests: modelo, contrato Firestore, códigos de invitación, snapshot del widget y modo demo).

Las reglas de seguridad viven en el repo (`firestore.rules`, `storage.rules`); se despliegan con:

```bash
firebase deploy --only firestore:rules,storage
```

### Activar push y login social (una vez, en las consolas)

La app ya lleva todo el código; falta activar los servicios:

1. **Sign in with Apple**: en [developer.apple.com](https://developer.apple.com) → Identifiers → `com.bpo.cuponeame` → marcar *Sign in with Apple*. En Firebase Console → Authentication → Sign-in method → habilitar **Apple**.
2. **Google**: Firebase Console → Authentication → Sign-in method → habilitar **Google**. El URL scheme ya está configurado vía `Config/Secrets.xcconfig` (copia `Secrets.example.xcconfig` si clonas en otra máquina).
3. **Push (FCM)**: en developer.apple.com → Keys → crear una **clave APNs** (Apple Push Notifications) y subir el `.p8` en Firebase Console → Configuración del proyecto → Cloud Messaging. Marcar también *Push Notifications* en el identifier.
4. **Cloud Functions** (avisan de regalos y canjes con la app cerrada): requiere plan **Blaze**. Desplegar con:

```bash
cd functions && npm install && cd .. && firebase deploy --only functions
```

5. **Monetización**: en [AdMob](https://apps.admob.com) crear la app y las unidades *intersticial* y *bonificado*, y ponerlas en `Config/Secrets.xcconfig` (`ADMOB_APP_ID`, `ADMOB_INTERSTITIAL_UNIT`, `ADMOB_REWARDED_UNIT`) — por defecto van los IDs de prueba de Google. En App Store Connect, crear el producto **no consumible** `com.bpo.cuponeame.premium` (sin él, el botón de compra aparece atenuado).

| Regla | Valor |
|---|---|
| Intersticial | Cada **3** aperturas de cupón (mínimo 45 s entre anuncios) |
| Cuota de creación | **5** cupones por mes natural |
| Anuncio bonificado | **+3** creaciones (caducan al cambiar de mes) |
| Premium | Pago único: sin anuncios + creaciones ilimitadas |

---

## 🗺️ Roadmap

- [x] Migración a XcodeGen + Firebase 12 + Liquid Glass
- [x] Crear/editar cupones con foto propia
- [x] Favoritos, filtros, buscador e historial
- [x] Modo demo para probar la app sin cuenta
- [x] **Modo pareja**: código de invitación, cuentas vinculadas y regalos de cupones
- [x] Aviso en vivo "💝 ¡Regalo de X!" al recibir un cupón (in-app, vía listeners)
- [x] Avatares personalizables (20 emojis + pingu clásico 🐧)
- [x] Widget «Próximo cupón» (WidgetKit + App Group)
- [x] Reglas de seguridad de Firestore/Storage por usuario (en el repo; falta desplegar + App Check)
- [x] Rediseño de identidad: logo vectorial + AppIcon nuevos, bienvenida animada y login/registro de marca
- [x] Rediseño interior: lista con saludo y buscador de marca, Crear con banner y tarjetas, carnet degradado en Ajustes e Historial con resumen
- [x] Push remota (FCM + Cloud Functions en `functions/`): regalos y canjes con la app cerrada — falta activar APNs/Blaze en consolas
- [x] Sign in with Apple y Google (falta habilitar los proveedores en Firebase Console)
- [x] Widgets de pantalla de bloqueo (circular y rectangular)
- [x] Monetización: intersticial cada 3 cupones, cuota mensual con anuncio bonificado y Premium de pago único

---

<div align="center">
<sub>Hecho con 💜 por <b>BPO Studios</b></sub>
</div>
