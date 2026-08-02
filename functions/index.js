/**
 * Push remota de Cuponéame (FCM). La app guarda el token del dispositivo en
 * users/{uid}.fcmToken; estas funciones avisan aunque la app esté cerrada:
 *
 * - Regalo entrante: se crea un cupón con `from` en tu talonario.
 * - Actividad de la pareja: tu pareja canjea un cupón.
 *
 * Deploy: firebase deploy --only functions  (requiere plan Blaze)
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 5 });

/** Token FCM de un usuario, o null si no tiene. */
async function tokenFor(uid) {
  const snapshot = await admin.firestore().doc(`users/${uid}`).get();
  return snapshot.get("fcmToken") || null;
}

async function send(token, title, body) {
  if (!token) return;
  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      apns: { payload: { aps: { sound: "default" } } },
    });
  } catch (error) {
    // Token caducado o app desinstalada: no es un fallo de la función.
    console.log("No se pudo enviar la push:", error.code || error.message);
  }
}

// Te ha llegado un regalo (cupón nuevo con `from` en tu talonario).
exports.regaloEntrante = onDocumentCreated(
  "users/{uid}/coupons/{couponId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || !data.from) return;
    const token = await tokenFor(event.params.uid);
    await send(
      token,
      "Te ha llegado un regalo",
      `${data.from} te ha enviado «${data.title || "un cupón"}».`
    );
  }
);

// Tu pareja ha canjeado un cupón (aviso al otro miembro del vínculo).
exports.canjeDePareja = onDocumentCreated(
  "users/{uid}/redemptions/{redemptionId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const user = await admin.firestore().doc(`users/${event.params.uid}`).get();
    const partnerUID = user.get("partnerUID");
    if (!partnerUID) return;
    const name = user.get("name") || "Tu pareja";
    const token = await tokenFor(partnerUID);
    await send(token, "Cupón canjeado", `${name} ha canjeado «${data.title || "un cupón"}».`);
  }
);
