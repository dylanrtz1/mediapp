import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'auth/onboarding_screen.dart';
import 'auth/complete_profile_screen.dart';
import 'screens/home_screen.dart';

import 'firebase_options.dart';

Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_ES', null);
  await _requestNotificationPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color lightBlue = Color(0xFF81D4FA);
    const Color primaryTextColor = Color(0xFF3A3A3A);

    return MaterialApp(
      title: 'Cirugías de Lujo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: lightBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryTextColor),
          titleTextStyle: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: primaryBlue, width: 2.0),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadePageTransitionsBuilder(),
            TargetPlatform.iOS: FadePageTransitionsBuilder(),
            TargetPlatform.windows: FadePageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3ba4f3),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Image.asset('assets/images/logo2.png', height: 180),
                const SizedBox(height: 24),
                const Text(
                  'Médicos certificados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'precios preferenciales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                  ),
                ),
                const Spacer(),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const Spacer(),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SafeArea(
                top: false,
                child: Text(
                  'Copyright 2025 Cirugías de Lujo\nTodos los derechos reservados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;
          if (user.isAnonymous) {
            return const HomeScreen();
          }
          // Usamos CheckUserProfile para verificar los datos de Firestore
          return CheckUserProfile(userId: user.uid);
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}

class CheckUserProfile extends StatelessWidget {
  final String userId;
  const CheckUserProfile({super.key, required this.userId});

  // Función auxiliar para obtener el valor del campo como String no nulo,
  // asegurando que sea una cadena vacía si no existe o es null.
  String _safeGetString(Map<String, dynamic> data, String key) {
    if (data.containsKey(key)) {
      // Usamos .toString() para manejar el caso de que el valor sea un número o null,
      // y luego trim() para eliminar espacios y asegurarnos que no sea solo " ".
      return (data[key]?.toString().trim() ?? '');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, firestoreSnapshot) {
        if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!firestoreSnapshot.hasData || !firestoreSnapshot.data!.exists) {
          debugPrint("DEBUG AUTH: Documento de usuario NO existe en Firestore. Redirigiendo a Completar Perfil.");
          return const CompleteProfileScreen();
        }

        final userData = firestoreSnapshot.data!.data() as Map<String, dynamic>;

        // Lógica de verificación de 3 campos obligatorios (nombre, apellido, telefono)
        final nombre = _safeGetString(userData, 'nombre');
        final apellido = _safeGetString(userData, 'apellido');
        final telefono = _safeGetString(userData, 'telefono');

        // El perfil está completo si NINGUNO de los 3 campos está vacío.
        final isProfileComplete = nombre.isNotEmpty && apellido.isNotEmpty && telefono.isNotEmpty;

        // *** LÓGICA CLAVE AÑADIDA ***
        final isFromCache = firestoreSnapshot.data!.metadata.isFromCache;

        // Si la verificación falla Y los datos provienen del caché,
        // esperamos el siguiente evento del Stream que vendrá del servidor.
        if (!isProfileComplete && isFromCache) {
          debugPrint("DEBUG AUTH: Perfil incompleto DETECTADO EN CACHÉ. Esperando datos del servidor...");
          return const Scaffold(body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3ba4f3)))));
        }

        // *** LOG DE DEBUGGING: Imprime todos los datos del documento (movido abajo) ***
        debugPrint("-------------------------------------------------------");
        debugPrint("DEBUG AUTH: Datos de usuario cargados para UID: $userId");
        debugPrint("DEBUG AUTH: Fuente de datos: ${isFromCache ? 'CACHE' : 'SERVER'}");
        userData.forEach((key, value) {
          debugPrint("DEBUG AUTH: Campo '$key': '$value'");
        });
        debugPrint("-------------------------------------------------------");

        // *** LOG DE DEBUGGING: Imprime el resultado de la verificación ***
        debugPrint("DEBUG AUTH: Verificación de Campos:");
        debugPrint("DEBUG AUTH: Nombre ('$nombre') OK: ${nombre.isNotEmpty}");
        debugPrint("DEBUG AUTH: Apellido ('$apellido') OK: ${apellido.isNotEmpty}");
        debugPrint("DEBUG AUTH: Teléfono ('$telefono') OK: ${telefono.isNotEmpty}");
        debugPrint("DEBUG AUTH: Resultado Final (isProfileComplete): $isProfileComplete");
        debugPrint("-------------------------------------------------------");


        if (isProfileComplete) {
          return const HomeScreen();
        } else {
          // Si alguno de los campos es vacío (nombre, apellido o telefono),
          // redirige a completar perfil.
          return const CompleteProfileScreen();
        }
      },
    );
  }
}

class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    if (route.isFirst) {
      return child;
    }
    return FadeTransition(opacity: animation, child: child);
  }
}