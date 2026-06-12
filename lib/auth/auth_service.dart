import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ================================================================
  // TOKEN FCM: GUARDADO INICIAL + ACTUALIZACIÓN AUTOMÁTICA (FIX iOS)
  // ================================================================
  Future<void> _saveOrUpdateDeviceToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) return;

      // 1. Pedimos permiso
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmError': 'Permisos denegados por el usuario en iOS',
        }, SetOptions(merge: true));
        return;
      }

      // 2. Esperar el APNs Token explícitamente en iOS
      String? apnsToken;
      if (Platform.isIOS) {
        apnsToken = await _fcm.getAPNSToken();
        int retries = 0;

        // Reintentamos 5 veces, dándole tiempo a iOS para generar el token
        while (apnsToken == null && retries < 5) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _fcm.getAPNSToken();
          retries++;
        }

        if (apnsToken == null) {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmError': 'APNs Token nativo es nulo. Revisa los Entitlements y Capabilities en Apple.',
          }, SetOptions(merge: true));
          return; // Salimos porque sin APNs de Apple, Firebase no nos dará el FCM Token
        }
      }

      // 3. Pedimos el token de Firebase
      final fcmToken = await _fcm.getToken();
      if (fcmToken == null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmError': 'FCM Token retornó nulo',
        }, SetOptions(merge: true));
        return;
      }

      // 4. Guardado exitoso (Limpiamos cualquier error previo)
      Map<String, dynamic> tokenData = {
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'fcmError': FieldValue.delete(), // Borra el error si ya funcionó
      };

      if (Platform.isIOS && apnsToken != null) {
        tokenData['apnsTokenNativo'] = apnsToken;
      }

      await _firestore.collection('users').doc(user.uid).set(tokenData, SetOptions(merge: true));
      print("Token FCM guardado/actualizado: $fcmToken");

    } catch (e) {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmError': e.toString(),
        }, SetOptions(merge: true));
      }
    }
  }

  void _setupTokenRefreshListener() {
    _fcm.onTokenRefresh.listen((newToken) async {
      final user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': newToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          print("Error al renovar token FCM: $e");
        }
      }
    });
  }

  AuthService() {
    _setupTokenRefreshListener();
  }

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error en modo invitado');
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _saveOrUpdateDeviceToken();
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