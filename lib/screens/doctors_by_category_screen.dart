import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import 'doctor_profile_screen.dart';

class DoctorsByCategoryScreen extends StatelessWidget {
  final String specialtyTitle;
  final List<Doctor> doctors;

  const DoctorsByCategoryScreen({
    super.key,
    required this.specialtyTitle,
    required this.doctors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo celeste fuerte "cromado"
          Container(
            color: const Color(0xFF00A9FF),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar personalizada
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: AppBar(
                    leading: const BackButton(color: Colors.white),
                    title: Text(specialtyTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                  ),
                ),
                // Grid de Doctores
                Expanded(
                  child: doctors.isEmpty
                      ? const Center(
                    child: Text(
                      'No hay doctores disponibles\nen esta categoría.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      return _buildDoctorAvatar(context, doctors[index]);
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
          MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'doctor_image_${doctor.id}',
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: doctor.imagePath.isNotEmpty ? NetworkImage(doctor.imagePath) : null,
                backgroundColor: Colors.grey.shade200,
                child: doctor.imagePath.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            doctor.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
