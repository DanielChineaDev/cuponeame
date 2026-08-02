# Publicar Cuponéame en la App Store

Guía de la primera subida. Todo lo que depende del código ya está hecho; lo que
queda son pasos en las consolas de Apple, Firebase y AdMob.

---

## 1. Antes de compilar: poner los IDs reales

> ⚠️ **Importante**: ahora mismo `Config/Secrets.xcconfig` lleva los **IDs de
> prueba de Google**. Si publicas así, los anuncios no generan ingresos.

En [AdMob](https://apps.admob.com) crea la app iOS y tres unidades (banner,
intersticial y bonificado), y sustituye en `Config/Secrets.xcconfig`:

```
ADMOB_APP_ID = ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
ADMOB_BANNER_UNIT = ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
ADMOB_INTERSTITIAL_UNIT = ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
ADMOB_REWARDED_UNIT = ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```

El `GID_REVERSED_CLIENT_ID` ya está puesto (sale del `GoogleService-Info.plist`).

## 2. Apple Developer · [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list)

En el identifier `com.bpo.cuponeame`, activar:

- **Push Notifications**
- **Sign in with Apple**
- **App Groups** → `group.com.bpo.cuponeame` (también en `com.bpo.cuponeame.widget`)

Y en **Keys**, crear una clave **APNs** (`.p8`) — se descarga una sola vez.

## 3. Firebase Console

- **Authentication › Sign-in method**: habilitar **Apple** y **Google**.
- **Configuración › Cloud Messaging**: subir la clave APNs (`.p8`) con su Key ID
  y el Team ID `9ZMNPYL827`.
- Pasar el proyecto al plan **Blaze** (necesario para Cloud Functions).
- Desplegar reglas y funciones:

```bash
firebase deploy --only firestore:rules,storage
cd functions && npm install && cd .. && firebase deploy --only functions
```

## 4. App Store Connect

Crear la app con el bundle `com.bpo.cuponeame` y rellenar:

- **Ficha**: nombre (*Cuponéame*), subtítulo, descripción, palabras clave,
  categoría (*Estilo de vida*), clasificación por edad (**17+** por el cupón de
  contenido íntimo del pack de ejemplo).
- **Capturas**: 6,7" y 6,5" obligatorias (las hay en `docs/capturas/`, hechas en
  iPhone 17 Pro — regenerar en el tamaño que pida la ficha).
- **URL de política de privacidad**:
  `https://github.com/DanielChineaDev/cuponeame/blob/main/docs/PRIVACIDAD.md`
- **App Privacy** (cuestionario): declarar correo, nombre, fotos, contenido del
  usuario, identificador de dispositivo (usado para publicidad) e interacción
  con el producto. Coincide con `PrivacyInfo.xcprivacy`.
- **Compra integrada**: producto **no consumible** `com.bpo.cuponeame.premium`
  ("Cuponéame Premium"), con precio y descripción. Sin esto, el botón de compra
  sale desactivado.
- **Notas para el revisor**: mencionar que existe **"Probar sin cuenta"** (modo
  demo) para revisar la app sin registrarse.

## 5. Compilar y subir

```bash
xcodebuild -project Cuponeame.xcodeproj -scheme Cuponeame -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Cuponeame.xcarchive \
  -allowProvisioningUpdates archive

xcodebuild -exportArchive -archivePath build/Cuponeame.xcarchive \
  -exportOptionsPlist Config/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates
```

En la exportación, Xcode crea el certificado y el perfil de **distribución** (es
cuando `aps-environment` pasa a `production`). Luego se sube el `.ipa` con
Transporter o con:

```bash
xcrun altool --upload-app -f build/export/Cuponeame.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

> Alternativa más simple: abrir `Cuponeame.xcodeproj` en Xcode →
> **Product › Archive** → *Distribute App* → *App Store Connect*.

## 6. Para las siguientes versiones

Subir `MARKETING_VERSION` (versión visible) y/o `CURRENT_PROJECT_VERSION`
(número de build, tiene que ser único por subida) en `project.yml`, y
`xcodegen generate`.

---

## Ya resuelto en el código

- Privacy manifests (app y widget), permisos de fotos y ATT, 47 SKAdNetworkIdentifier.
- Eliminar cuenta, Sign in with Apple junto a Google, restaurar compras.
- Consentimiento RGPD (UMP) reabrible desde Ajustes.
- Política de privacidad y términos enlazados desde la app.
- `aps-environment` por configuración y archive en Release.
