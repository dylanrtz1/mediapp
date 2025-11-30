import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore"; // NOVEDAD: Import para triggers de Firestore
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// Función auxiliar para verificar si el usuario es Admin
const ensureIsAdmin = async (context: any) => {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Debes estar autenticado.");
  }
  const adminDoc = await db.collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Esta acción requiere permisos de administrador.");
  }
};

// --- FUNCIÓN PARA CREAR DOCTOR ---
export const createDoctor = onCall(async (request) => {
  await ensureIsAdmin(request);

  const {email, password} = request.data.auth;
  const profile = request.data.profile;

  try {
    const userRecord = await admin.auth().createUser({email, password, displayName: profile.name});
    
    await db.collection("users").doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      role: "doctor",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const fullProfile = {
      ...profile,
      authUid: userRecord.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const docRef = await db.collection("doctors").add(fullProfile);

    return {success: true, uid: userRecord.uid, docId: docRef.id};
  } catch (error) {
    if (error instanceof Error) throw new HttpsError("internal", error.message);
    throw new HttpsError("internal", "Ocurrió un error desconocido.");
  }
});

// --- FUNCIÓN PARA ACTUALIZAR DOCTOR ---
export const updateDoctor = onCall(async (request) => {
  await ensureIsAdmin(request);

  const {docId, profileData} = request.data;
  if (!docId || !profileData) {
    throw new HttpsError("invalid-argument", "Faltan datos (docId, profileData).");
  }

  try {
    const docRef = db.collection("doctors").doc(docId);
    await docRef.update(profileData);
    return {success: true};
  } catch (error) {
    if (error instanceof Error) throw new HttpsError("internal", error.message);
    throw new HttpsError("internal", "Error desconocido al actualizar.");
  }
});

// --- FUNCIÓN PARA ELIMINAR DOCTOR ---
export const deleteDoctor = onCall(async (request) => {
  await ensureIsAdmin(request);

  const {docId} = request.data;
  if (!docId) {
    throw new HttpsError("invalid-argument", "Falta el ID del documento.");
  }

  try {
    const docRef = db.collection("doctors").doc(docId);
    await docRef.delete();
    return {success: true};
  } catch (error) {
    if (error instanceof Error) throw new HttpsError("internal", error.message);
    throw new HttpsError("internal", "Error desconocido al eliminar.");
  }
});

// =======================================================================
// NOVEDAD: FUNCIÓN AUTOMÁTICA PARA NOTIFICAR CAMBIOS DE ESTADO EN CITAS
// =======================================================================
export const notificarCambioDeEstadoCita = onDocumentUpdated("pagos/{pagoId}", async (event) => {
  // Obtiene los datos del documento antes y después del cambio.
  const datosAnteriores = event.data?.before.data();
  const datosNuevos = event.data?.after.data();

  // Si no hay datos o el estado no cambió, no hacemos nada.
  if (!datosAnteriores || !datosNuevos || datosAnteriores.status === datosNuevos.status) {
    console.log("El estado no cambió o no hay datos, no se envía notificación.");
    return;
  }

  const patientId = datosNuevos.patientId;
  if (!patientId) {
    console.log("El documento no tiene 'patientId'.");
    return;
  }

  // Busca el documento del usuario para obtener su token de notificación.
  const userDoc = await db.collection("users").doc(patientId).get();
  if (!userDoc.exists) {
    console.log(`No se encontró al usuario con ID: ${patientId}`);
    return;
  }

  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) {
    console.log(`El usuario ${patientId} no tiene un token FCM.`);
    return;
  }

  let tituloNotificacion = "";
  let cuerpoNotificacion = "";

  // Preparamos el mensaje según el nuevo estado.
  if (datosNuevos.status === "aprobado") {
    tituloNotificacion = "¡Cita Aprobada! 🎉";
    cuerpoNotificacion = `Tu cita con el Dr. ${datosNuevos.doctorName} ha sido confirmada.`;
  } else if (datosNuevos.status === "rechazado") {
    tituloNotificacion = "Cita Rechazada 🔴";
    cuerpoNotificacion = "Hubo un problema con tu solicitud de cita. Contacta a soporte para más detalles.";
  } else {
    // Si el cambio es a otro estado (ej. 'pendiente'), no notificamos.
    console.log(`Estado cambiado a '${datosNuevos.status}', no se requiere notificación.`);
    return;
  }

  // Contenido de la notificación push.
  const payload = {
    notification: {
      title: tituloNotificacion,
      body: cuerpoNotificacion,
      sound: "default",
    },
    // Opcional: puedes enviar datos extra para manejar la notificación en la app
    data: {
      screen: "mis_citas",
      pagoId: event.params.pagoId,
    },
  };

  console.log(`Enviando notificación al token: ${fcmToken}`);
  
  // Enviamos la notificación al dispositivo del usuario.
  try {
    await admin.messaging().sendToDevice(fcmToken, payload);
    console.log("Notificación enviada con éxito.");
  } catch (error) {
    console.error("Error al enviar la notificación:", error);
  }
});