import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';
import 'doctor_profile_screen.dart';
import 'home_screen.dart'; // Importante: Asegúrate de importar home_screen para usar AnimatedBubblesBackground

class DoctorsByCategoryScreen extends StatefulWidget {
  final String specialtyTitle;
  final List<Doctor> doctors;

  const DoctorsByCategoryScreen({
    super.key,
    required this.specialtyTitle,
    required this.doctors,
  });

  @override
  State<DoctorsByCategoryScreen> createState() => _DoctorsByCategoryScreenState();
}

class _DoctorsByCategoryScreenState extends State<DoctorsByCategoryScreen> {
  String _userCity = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectUserCity();
  }

  Future<void> _detectUserCity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.isAnonymous) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          _userCity = (data?['city'] ?? "").toString().trim();
        }
      }
    } catch (e) {
      print("Error detectando ciudad del usuario: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Doctor> _getFilteredDoctors() {
    if (_userCity.isEmpty) {
      return [];
    }

    final userCityNorm = _userCity.toLowerCase();

    return widget.doctors.where((doctor) {
      final doctorCityNorm = doctor.city.trim().toLowerCase();
      return doctorCityNorm == userCityNorm;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _getFilteredDoctors();
    String displayCity = _userCity.isNotEmpty ? _userCity : "tu ciudad (no detectada)";

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFF00A9FF),
          ),
          // Capa de fondo animada con desenfoque de burbujas infinitas
          const Positioned.fill(
            child: AnimatedBubblesBackground(),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: AppBar(
                    leading: const BackButton(color: Colors.white),
                    title: Text(
                      widget.specialtyTitle,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  color: Colors.white.withOpacity(0.1),
                  child: Text(
                    _isLoading
                        ? "Buscando tu ciudad..."
                        : "Mostrando médicos en \"$displayCity\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : filteredDoctors.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 60,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No hay doctores disponibles en\n$displayCity para esta especialidad.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        if (_userCity.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              'Verifica tu registro de ciudad.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: filteredDoctors.length,
                    itemBuilder: (context, index) {
                      return _buildDoctorAvatar(
                        context,
                        filteredDoctors[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAvatar(BuildContext context, Doctor doctor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorProfileScreen(doctor: doctor),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'doctor_image_${doctor.id}',
            child: Container(
              width: 84, // Tamaño total del círculo
              height: 84,
              padding: const EdgeInsets.all(3), // Espacio entre el borde de cristal y la foto
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15), // Fondo translúcido (Cristal)
                border: Border.all(
                  color: Colors.white.withOpacity(0.6), // Borde blanco brillante
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5), // Sombra suave hacia abajo
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: Colors.white.withOpacity(0.2), // Fondo por si no hay imagen
                  child: doctor.imagePath.isNotEmpty
                      ? Image.network(
                    doctor.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Efecto cristal muy transparente (solo un 10% de blanco)
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12), // Bordes redondeados (estilo píldora)
                border: Border.all(
                  color: Colors.white.withOpacity(0.5), // Borde blanco brillante para simular el reflejo
                  width: 0.5,
                ),
              ),
              child: Text(
                doctor.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  // Añadimos una sombra sutil al texto para que no se pierda en el fondo transparente
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 3,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}