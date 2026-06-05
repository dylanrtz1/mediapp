import {onCall, HttpsError, onRequest} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Inicialización de Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp();
}
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

// =======================================================================
// NUEVA: FUNCIÓN PARA SEMBRAR DATOS DE PRUEBA (SEEDING)
// URL de invocación: https://us-central1-TU-PROYECTO.cloudfunctions.net/seedDoctors
// =======================================================================
export const seedDoctors = onRequest(async (req, res) => {
  const batch = db.batch(); // Usamos batch para escribir todo de una sola vez
  
  // Las 3 categorías principales
  const categories = [
    { id: "ODONTOLÓGICA", title: "Odontología" },
    { id: "CIRUGÍA ESTÉTICA", title: "Cirugía Estética" },
    { id: "CIRUGÍA BARIATRICA", title: "Cirugía Bariátrica" }
  ];

  // Ciudades para probar el filtro
  const cities = ["Guayaquil", "Quito"];

  // Imágenes de prueba (reusamos la que diste para que no falle la carga)
  const defaultImage = "https://firebasestorage.googleapis.com/v0/b/lisafetyapp-8ccb8.firebasestorage.app/o/markers%2FPkJeJ5V3leT3eGcL8Ucg95hlq1P2%2F11f960f7-3e3c-4b83-a788-912f2f7c4927.jpg?alt=media&token=9c666112-6f99-4223-a608-74c63306a482";
  const defaultVideo = "https://firebasestorage.googleapis.com/v0/b/cirujias-c8336.firebasestorage.app/o/VID-20250215-WA0093%5B1%5D.mp4?alt=media&token=39657c99-43f8-4ed5-a499-c14e7f26314a";

  let totalDocs = 0;

  try {
    // Bucle por categorías
    for (const cat of categories) {
      
      // Creamos 10 doctores por cada categoría
      for (let i = 1; i <= 10; i++) {
        // Generamos un ID nuevo automáticamente
        const docRef = db.collection("doctors").doc();
        
        // Alternamos ciudad: Par = Guayaquil, Impar = Quito
        const city = cities[i % 2]; 

        // Construimos el objeto Doctor con TODOS los campos requeridos
        const doctorData = {
          name: `Dr. Prueba ${cat.title} ${i}`,
          about: "Este es un perfil generado automáticamente para pruebas de desarrollo. El doctor cuenta con amplia experiencia simulada y certificaciones placeholder.",
          
          // Generamos un UID falso aleatorio
          authUid: `mock_uid_${cat.id}_${i}_${Date.now()}`,
          
          city: city, // ¡Importante para tu filtro!
          specialty: cat.id,
          subSpecialty: "Especialista General",
          
          // Datos numéricos y booleanos
          casesPerformed: Math.floor(Math.random() * 500) + 50, // Entre 50 y 550
          yearsOfExperience: Math.floor(Math.random() * 20) + 5,
          priceRegular: 100 + (i * 10),
          priceWithApp: 80 + (i * 10),
          rating: (Math.random() * (5.0 - 3.5) + 3.5).toFixed(1), // Rating entre 3.5 y 5.0
          reviewCount: Math.floor(Math.random() * 100),
          isFeatured: i === 1, // Solo el primero de cada grupo es destacado
          isVerified: true,
          
          // Datos de Registro
          mspRegistrationNumber: `MSP-${Math.floor(Math.random() * 90000) + 10000}`,
          senescytRegistrationNumber: `SEN-${Math.floor(Math.random() * 90000) + 10000}`,
          
          // Multimedia (Usamos las URLs que sabemos que funcionan)
          imagePath: defaultImage,
          paymentLink: "https://ppls.me/Zyy6r0VXS1NDl8pdR9XJFA",
          
          // Arrays complejos
          bankAccounts: [
            {
              bankName: "BANCO DEL AUSTRO",
              accountType: "AHORRO",
              accountNumber: "2209854236",
              beneficiaryName: "SIMON BOLIVAR",
              beneficiaryId: "0921365428"
            },
            {
              bankName: "PICHINCHA",
              accountType: "CORRIENTE",
              accountNumber: "1234567890",
              beneficiaryName: "SIMON BOLIVAR",
              beneficiaryId: "0921365428"
            }
          ],
          
          beforeAndAfterImageUrls: [
            { before: defaultImage, after: defaultImage },
            { before: defaultImage, after: defaultImage }
          ],
          
          courses: [
            { title: "CONGRESO INTERNACIONAL 2025", videoUrl: defaultVideo },
            { title: "MASTERCLASS AVANZADA", videoUrl: defaultVideo }
          ],
          
          services: [
            {
              name: "Consulta Primera Vez",
              description: "Evaluación completa inicial",
              priceRegular: 60,
              priceWithApp: 30,
              image: defaultImage
            },
            {
              name: `Procedimiento ${cat.title}`,
              description: "Tratamiento especializado con tecnología de punta",
              priceRegular: 300,
              priceWithApp: 250,
              image: defaultImage
            }
          ],

          // Timestamps
          createdAt: new Date().toISOString(),
        };

        batch.set(docRef, doctorData);
        totalDocs++;
      }
    }

    // Ejecutamos el guardado masivo
    await batch.commit();

    res.status(200).send({
      success: true,
      message: `Se inyectaron exitosamente ${totalDocs} doctores.`,
      distribution: "10 Odontología, 10 Estética, 10 Bariátrica",
      cities: "Alternadas entre Guayaquil y Quito"
    });

  } catch (error) {
    console.error("Error inyectando datos:", error);
    res.status(500).send({
      success: false,
      error: (error as Error).message
    });
  }
});