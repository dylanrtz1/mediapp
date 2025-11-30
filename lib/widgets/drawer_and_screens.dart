import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/auth_service.dart';

const Color skyBlue = Color(0xFF29B6F6);

//==============================================================================
// 1. APP DRAWER (MENÚ LATERAL)
//==============================================================================

class AppDrawer extends StatelessWidget {
  final bool isGuest;
  final VoidCallback onSignOut;

  const AppDrawer({
    super.key,
    required this.isGuest,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = isGuest ? 'Invitado' : (user?.displayName ?? user?.email?.split('@')[0] ?? "Usuario");
    final email = isGuest ? 'Explorando la app' : (user?.email ?? "email@ejemplo.com");
    final initial = isGuest ? '?' : (displayName.isNotEmpty ? displayName[0].toUpperCase() : "?");
    final photoUrl = user?.photoURL;

    return Drawer(
      backgroundColor: skyBlue,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(context, initial, displayName, email, photoUrl),

          if (!isGuest) ...[
            _buildDrawerItem(
              context,
              icon: Icons.person_outline,
              text: 'Mi Perfil',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfileScreen()));
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.calendar_month_outlined,
              text: 'Mis Citas',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()));
              },
            ),
            const Divider(thickness: 1, indent: 16, endIndent: 16, color: Colors.white30),
          ],

          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            text: 'Ayuda y Soporte',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpAndSupportScreen()));
            },
          ),
          const Divider(thickness: 1, indent: 16, endIndent: 16, color: Colors.white30),

          _buildDrawerItem(
            context,
            icon: isGuest ? Icons.login : Icons.logout,
            text: isGuest ? 'Iniciar Sesión / Registrarse' : 'Cerrar Sesión',
            color: Colors.white,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, String initial, String name, String email, String? photoUrl) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                initial,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: skyBlue,
                ),
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap, Color? color}) {
    final itemColor = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        text,
        style: TextStyle(fontSize: 16, color: itemColor),
      ),
      onTap: onTap,
    );
  }
}

//==============================================================================
// 2. PANTALLA "MI PERFIL"
//==============================================================================

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isUploading = false;

  Future<void> _resetPassword(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se ha enviado un correo para restablecer tu contraseña.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el correo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final storageRef = FirebaseStorage.instance.ref().child('user_profiles/${user.uid}.jpg');
        await storageRef.putFile(File(image.path));
        final String downloadUrl = await storageRef.getDownloadURL();

        // Actualizar Auth
        await user.updatePhotoURL(downloadUrl);

        // Actualizar Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: skyBlue,
        appBar: AppBar(
          title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text('No se pudo cargar el perfil.', style: TextStyle(color: Colors.white))),
      );
    }

    // Usamos setState para refrescar la UI al subir foto, pero también necesitamos datos de Firestore
    return Scaffold(
      backgroundColor: skyBlue,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          Map<String, dynamic> userData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            userData = snapshot.data!.data() as Map<String, dynamic>;
          }

          final nombre = userData['nombre'] ?? user.displayName ?? 'No disponible';
          final apellido = userData['apellido'] ?? '';
          final email = userData['email'] ?? user.email ?? 'No disponible';
          final telefono = userData['telefono'] ?? 'No disponible';

          // Priorizamos la URL de Auth ya que la acabamos de actualizar, sino Firestore
          final photoUrl = user.photoURL ?? userData['photoUrl'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(context, nombre, email, photoUrl),
              const SizedBox(height: 32),
              _buildInfoCard(context, 'Información Personal', [
                _buildInfoTile(Icons.person_outline, 'Nombre Completo', '$nombre $apellido'),
                _buildInfoTile(Icons.email_outlined, 'Correo Electrónico', email),
                _buildInfoTile(Icons.phone_outlined, 'Teléfono', telefono),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard(context, 'Seguridad', [
                ListTile(
                  leading: Icon(Icons.lock_reset, color: skyBlue),
                  title: const Text('Restablecer contraseña', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: skyBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Restablecer Contraseña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text(
                          'Se enviará un correo para restablecer tu contraseña a:\n\n$email\n\n¿Deseas continuar?',
                          style: const TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: skyBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Enviar Correo'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _resetPassword(context, email);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email, String? photoUrl) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _uploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (photoUrl == null
                      ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      : null),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _uploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: skyBlue, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(email, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: skyBlue)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//==============================================================================
// 3. PANTALLA "MIS CITAS"
//==============================================================================

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
      case 'agendado':
        return {
          'text': 'Aprobado',
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
          'message': '¡Todo listo! Tu cita ha sido confirmada.'
        };
      case 'pendiente':
        return {
          'text': 'Pendiente',
          'color': Colors.orange,
          'icon': Icons.hourglass_empty_rounded,
          'message': 'Tu pago está siendo revisado.'
        };
      case 'rechazado':
        return {
          'text': 'Rechazado',
          'color': Colors.red,
          'icon': Icons.cancel_rounded,
          'message': 'Hubo un problema con tu pago.'
        };
      default:
        return {
          'text': 'Desconocido',
          'color': Colors.grey,
          'icon': Icons.help_outline_rounded,
          'message': 'Estado desconocido.'
        };
    }
  }

  void _showReceiptDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: skyBlue)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: skyBlue,
        appBar: AppBar(title: const Text('Mis Citas'), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Debes iniciar sesión para ver tus citas.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: skyBlue,
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pagos').where('patientId', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocurrió un error al cargar tus citas.', style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text('Aún no tienes citas agendadas.', style: TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointmentData = appointments[index].data() as Map<String, dynamic>;
              return _buildAppointmentCard(context, appointmentData);
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> data) {
    final String doctorName = data['doctorName'] ?? 'Doctor no especificado';
    final Timestamp timestamp = data['appointmentDate'] ?? Timestamp.now();
    final DateTime date = timestamp.toDate();
    final String status = data['status'] ?? 'desconocido';
    final String paymentMethod = data['paymentMethod'] == 'card' ? 'Tarjeta de Crédito' : 'Transferencia';
    final String receiptUrl = data['receiptUrl'] ?? '';

    final statusInfo = _getStatusInfo(status);

    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(doctorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusInfo['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today_outlined, '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
            _buildInfoRow(Icons.credit_card_outlined, paymentMethod),
            if (receiptUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Ver Comprobante'),
                onPressed: () => _showReceiptDialog(context, receiptUrl),
                style: OutlinedButton.styleFrom(
                  foregroundColor: skyBlue,
                  side: const BorderSide(color: skyBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusInfo['color'].withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusInfo['color'].withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(statusInfo['icon'], color: statusInfo['color'], size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(statusInfo['message'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.w500, fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}

//==============================================================================
// 4. PANTALLA "AYUDA Y SOPORTE"
//==============================================================================

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: skyBlue,
      appBar: AppBar(
        title: const Text('Ayuda y Soporte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preguntas Frecuentes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildExpansionTile('¿Cómo agendo una cita?', 'Para agendar una cita, primero selecciona al médico de tu preferencia en la pantalla principal. Luego, en su perfil, pulsa el botón "Agendar y Pagar" y sigue las instrucciones para completar el pago de tu reserva o procedimiento.'),
            _buildExpansionTile('¿Son seguros los pagos en la app?', 'Sí. Los pagos con tarjeta se procesan a través de PayPhone, una pasarela de pagos segura y reconocida. Para las transferencias bancarias, te proporcionamos los datos directos del médico y puedes subir tu comprobante para validación.'),
            _buildExpansionTile('¿Qué pasa si no califico para la cirugía?', 'Tu salud es nuestra prioridad. Si después de la valoración médica, el doctor determina que no eres candidato para el procedimiento, se aplicará la política de devolución. Se te reembolsará el monto pagado menos una tasa administrativa por los costos de la consulta y gestión, tal como se detalla en los Términos y Condiciones.'),
            _buildExpansionTile('¿Cómo puedo ver mis citas agendadas?', 'Puedes ver todas tus citas, tanto pasadas como futuras, en la sección "Mis Citas" que se encuentra en el menú lateral de la aplicación. Allí verás el estado de cada una (Pendiente, Aprobado, etc.).'),
            const Divider(height: 40, color: Colors.white30),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile(String title, String content) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        iconColor: skyBlue,
        collapsedIconColor: Colors.grey,
        children: [Text(content, textAlign: TextAlign.justify, style: TextStyle(color: Colors.grey.shade700, height: 1.5))],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Text('¿Necesitas más ayuda?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 8),
          Text('Contáctanos directamente a nuestro número de soporte.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.support_agent, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text('+593 594 352 145', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}