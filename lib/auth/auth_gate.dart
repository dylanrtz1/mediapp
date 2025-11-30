import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'complete_profile_screen.dart';
import 'login_screen.dart';
import 'package:mediapp/screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen("Verificando sesión...");
        }

        if (authSnapshot.hasData && authSnapshot.data != null && !authSnapshot.data!.isAnonymous) {
          return _ProfileCheckGate(userId: authSnapshot.data!.uid);
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _ProfileCheckGate extends StatelessWidget {
  final String userId;
  const _ProfileCheckGate({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userDocSnapshot) {
        if (userDocSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen("Cargando perfil...");
        }

        if (userDocSnapshot.hasError) {
          return _buildErrorScreen(context, userDocSnapshot.error);
        }

        if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
          return const CompleteProfileScreen();
        }

        final userData = userDocSnapshot.data!.data() as Map<String, dynamic>?;

        final nombre = userData?['nombre'] as String?;
        final apellido = userData?['apellido'] as String?;
        final telefono = userData?['telefono'] as String?;

        final isProfileComplete =
            (nombre != null && nombre.trim().isNotEmpty) &&
                (apellido != null && apellido.trim().isNotEmpty) &&
                (telefono != null && telefono.trim().isNotEmpty);

        if (isProfileComplete) {
          return const HomeScreen();
        } else {
          return const CompleteProfileScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, Object? error) {
    debugPrint("Error en _ProfileCheckGate: $error");

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
              const SizedBox(height: 20),
              const Text(
                "Ocurrió un error inesperado",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "No pudimos cargar tu información. Por favor, revisa tu conexión a internet e inténtalo de nuevo.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar Sesión"),
                onPressed: () => FirebaseAuth.instance.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}