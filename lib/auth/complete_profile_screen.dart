import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../screens/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryTextColor = Color(0xFF3A3A3A);

  String _selectedCity = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.displayName != null) {
      final nameParts = user!.displayName!.split(' ');
      _nombreController.text = nameParts.first;
      _apellidoController.text =
      nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCity = prefs.getString('user_city') ?? '';
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona una ciudad válida para continuar.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No hay usuario autenticado.");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'city': _selectedCity,
        'email': user.email,
        'uid': user.uid,
        'role': 'paciente',
      }, SetOptions(merge: true));

      if (mounted) {
        //  CORRECCIÓN 1: Cambiado pop() por pushReplacement() para evitar la pantalla negra
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
        const Text('Completar Perfil', style: TextStyle(color: primaryTextColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF00A9FF)),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),

          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                              height:
                              MediaQuery.of(context).padding.top + kToolbarHeight),
                          Image.asset(
                            'assets/images/logo2.png',   //
                            height: 120,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.medical_services_outlined,
                                color: primaryBlue, size: 100),
                          ),
                          const SizedBox(height: 16),

                          const Text('Completa tu Perfil',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 8),

                          Text(
                            'Necesitamos tus datos para continuar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9)),
                          ),
                          const SizedBox(height: 24),

                          _buildTextField(
                              controller: _nombreController,
                              label: 'Nombres',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'))
                              ]),
                          const SizedBox(height: 16),

                          _buildTextField(
                              controller: _apellidoController,
                              label: 'Apellidos',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'))
                              ]),
                          const SizedBox(height: 16),


                          _buildTextField(
                              controller: _telefonoController,
                              label: 'Teléfono',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10), // Limita visualmente
                              ]),
                          const SizedBox(height: 24),



                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('GUARDAR Y CONTINUAR',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
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
                        Shadow(
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.7)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: primaryTextColor),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide:
            const BorderSide(color: primaryBlue, width: 2.0)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio.';
        }
        // Validación de longitud estricta a 10 dígitos
        if (label == 'Teléfono' && value.trim().length != 10) {
          return 'El número de teléfono debe ser de exactamente 10 dígitos.';
        }
        return null;
      },
    );
  }
}