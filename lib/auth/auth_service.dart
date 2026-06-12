import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ================================================================
  // TOKEN FCM: GUARDADO INICIAL + ACTUALIZACIÓN AUTOMÁTICA (NUNCA FALLA)
  // ================================================================
  Future<void> _saveOrUpdateDeviceToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) return;

      // 1. Pedimos permiso y verificamos la respuesta
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print("Permisos de notificaciones denegados por el usuario.");
        return;
      }

      // 2. FIX CRÍTICO PARA iOS: Esperar el APNs Token explícitamente
      if (Platform.isIOS) {
        // Firebase en iOS necesita el APNs token antes de generar el FCM token
        String? apnsToken = await _fcm.getAPNSToken();
        int retries = 0;

        // Reintentar hasta 5 veces (esperando 1 seg) porque iOS puede demorar
        while (apnsToken == null && retries < 5) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _fcm.getAPNSToken();
          retries++;
        }

        if (apnsToken == null) {
          print("ERROR CRÍTICO IOS: Nunca se recibió el APNs Token de Apple.");
          print("Falta habilitar la Capability de 'Push Notifications'.");
        } else {
          print("APNs Token nativo recibido con éxito: $apnsToken");
        }
      }

      // 3. Ahora sí pedimos el token de Firebase
      final fcmToken = await _fcm.getToken();
      if (fcmToken == null) {
        print("No se pudo obtener el token FCM");
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Token FCM guardado/actualizado: $fcmToken");
    } catch (e) {
      print("Error al guardar token FCM: $e");
    }
  }

  // Listener que se ejecuta AUTOMÁTICAMENTE cuando Firebase renueva el token
  // (esto es lo que hacía que fallara antes: si no lo tienes, el token viejo deja de funcionar)
  void _setupTokenRefreshListener() {
    _fcm.onTokenRefresh.listen((newToken) async {
      final user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': newToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print("Token FCM renovado automáticamente: $newToken");
        } catch (e) {
          print("Error al renovar token FCM: $e");
        }
      }
    });
  }

  // ================================================================
  // CONSTRUCTOR: Activa el listener desde el primer momento
  // ================================================================
  AuthService() {
    // Esto se ejecuta una sola vez cuando creas AuthService()
    _setupTokenRefreshListener();
  }

  // ================================================================
  // MÉTODOS DE AUTENTICACIÓN (todos con token actualizado)
  // ================================================================

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      print("Invitado: ${userCredential.user?.uid}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error en modo invitado');
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _saveOrUpdateDeviceToken(); // Token fresco al loguear
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error al iniciar sesión');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'nombre': userCredential.user!.displayName ?? '',
          'apellido': '',
          'email': userCredential.user!.email ?? '',
          'role': 'paciente',
          'createdAt': FieldValue.serverTimestamp(),
          'cedula': '',
          'telefono': '',
          'city': '',
        });
      }

      await _saveOrUpdateDeviceToken();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error con Google');
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;

      final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'nombre': userCredential.user!.displayName ?? '',
          'apellido': '',
          'email': userCredential.user!.email ?? '',
          'role': 'paciente',
          'createdAt': FieldValue.serverTimestamp(),
          'cedula': '',
          'telefono': '',
          'city': '',
        });
      }

      await _saveOrUpdateDeviceToken();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error con Facebook');
    }
  }

  Future<User?> registerPatient({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String city,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'nombre': nombre,
          'apellido': apellido,
          'cedula': cedula,
          'email': email,
          'telefono': telefono,
          'city': city,
          'role': 'paciente',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _saveOrUpdateDeviceToken();
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error en registro');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'No se pudo enviar el correo');
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await GoogleSignIn().signOut();
        await FacebookAuth.instance.logOut();
      } catch (e) {
        print("Error cerrando sesión social: $e");
      }
    }
    await _auth.signOut();
  }
}