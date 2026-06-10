import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

const Color skyBlue = Color(0xFF29B6F6);

//==============================================================================
// 1. APP DRAWER
//==============================================================================

class AppDrawer extends StatefulWidget {
  final bool isGuest;
  final VoidCallback onSignOut;

  const AppDrawer({
    super.key,
    required this.isGuest,
    required this.onSignOut,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    List<Widget> drawerItems = [
      _buildAnimatedItem(
        index: 1,
        child: _buildDrawerHeader(context, user, widget.isGuest),
      ),
      const SizedBox(height: 10),
    ];

    if (!widget.isGuest) {
      drawerItems.addAll([
        _buildAnimatedItem(
          index: 2,
          child: _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            text: 'Mi Perfil',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfileScreen()));
            },
          ),
        ),
        _buildAnimatedItem(
          index: 3,
          child: _buildDrawerItem(
            context,
            icon: Icons.calendar_month_outlined,
            text: 'Mis Citas',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()));
            },
          ),
        ),
        const SizedBox(height: 10),
      ]);
    }

    drawerItems.addAll([
      _buildAnimatedItem(
        index: widget.isGuest ? 2 : 4,
        child: _buildDrawerItem(
          context,
          icon: Icons.help_outline,
          text: 'Ayuda y Soporte',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpAndSupportScreen()));
          },
        ),
      ),
      const SizedBox(height: 20),
      _buildAnimatedItem(
        index: widget.isGuest ? 3 : 5,
        child: _buildDrawerItem(
          context,
          icon: widget.isGuest ? Icons.login : Icons.logout,
          text: widget.isGuest ? 'Iniciar Sesión / Registrarse' : 'Cerrar Sesión',
          isLogout: true,
          onTap: widget.onSignOut,
        ),
      ),
      const SizedBox(height: 30),
    ]);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(35)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: drawerItems,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    final animation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic)),
    );
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0, curve: Curves.easeOut)),
    );
    return SlideTransition(position: animation, child: FadeTransition(opacity: fadeAnimation, child: child));
  }

  Widget _buildDrawerHeader(BuildContext context, User? user, bool isGuest) {
    if (isGuest || user == null) {
      return _buildHeaderContent('Invitado', 'Explorando la app', '?', null);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String name = user.displayName ?? user.email?.split('@')[0] ?? "Usuario";
        String email = user.email ?? "email@ejemplo.com";
        String? photoUrl = user.photoURL;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nombre = data['nombre'] ?? '';
          final apellido = data['apellido'] ?? '';
          final fullName = '$nombre $apellido'.trim();

          if (fullName.isNotEmpty) name = fullName;
          if (data['photoUrl'] != null) photoUrl = data['photoUrl'];
        }

        final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

        return _buildHeaderContent(name, email, initial, photoUrl);
      },
    );
  }

  Widget _buildHeaderContent(String name, String email, String initial, String? photoUrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? Text(initial, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: skyBlue)) : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: Text(email, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap, bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isLogout ? Colors.white : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLogout ? Colors.transparent : Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: isLogout ? const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : [],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: isLogout ? skyBlue : Colors.white, size: 26),
        title: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isLogout ? skyBlue : Colors.white)),
        trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        onTap: onTap,
      ),
    );
  }
}

//==============================================================================
// 2. MI PERFIL
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Se ha enviado un correo.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _uploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final storageRef = FirebaseStorage.instance.ref().child('user_profiles/${user.uid}.jpg');
        await storageRef.putFile(File(image.path));
        final String downloadUrl = await storageRef.getDownloadURL();
        await user.updatePhotoURL(downloadUrl);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photoUrl': downloadUrl});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: skyBlue,
        appBar: AppBar(title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
        body: const Center(child: Text('No se pudo cargar el perfil.', style: TextStyle(color: Colors.white))),
      );
    }

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
          if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) return const Center(child: CircularProgressIndicator(color: Colors.white));

          Map<String, dynamic> userData = {};
          if (snapshot.hasData && snapshot.data!.exists) userData = snapshot.data!.data() as Map<String, dynamic>;

          final nombre = userData['nombre'] ?? user.displayName ?? 'No disponible';
          final apellido = userData['apellido'] ?? '';
          final email = userData['email'] ?? user.email ?? 'No disponible';
          final telefono = userData['telefono'] ?? 'No disponible';
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
                  leading: const Icon(Icons.lock_reset, color: skyBlue),
                  title: const Text('Restablecer contraseña', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: skyBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Restablecer Contraseña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text('Se enviará un correo a:\n\n$email\n\n¿Deseas continuar?', style: const TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(child: const Text('Cancelar', style: TextStyle(color: Colors.white)), onPressed: () => Navigator.of(dialogContext).pop()),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: skyBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            child: const Text('Enviar Correo'),
                            onPressed: () { Navigator.of(dialogContext).pop(); _resetPassword(context, email); },
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
                  child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : (photoUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)) : null),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploadImage,
                  child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: skyBlue, size: 20)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: skyBlue)), const Divider(height: 24), ...children]),
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))])),
        ],
      ),
    );
  }
}

//==============================================================================
// 3. MIS CITAS (CON FILTROS ELEGANTE Y ELIMINACIÓN)
//==============================================================================

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  String _currentFilter = 'Todas'; // 'Todas', 'Próximas', 'Pasadas', 'Rango'
  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
      case 'agendado':
        return {'text': 'Aprobado', 'color': Colors.green, 'icon': Icons.check_circle_rounded, 'message': '¡Todo listo! Tu cita ha sido confirmada.'};
      case 'pendiente':
        return {'text': 'Pendiente', 'color': Colors.orange, 'icon': Icons.hourglass_empty_rounded, 'message': 'Tu pago está siendo revisado.'};
      case 'rechazado':
        return {'text': 'Rechazado', 'color': Colors.red, 'icon': Icons.cancel_rounded, 'message': 'Hubo un problema con tu pago.'};
      default:
        return {'text': 'Desconocido', 'color': Colors.grey, 'icon': Icons.help_outline_rounded, 'message': 'Estado desconocido.'};
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(8),
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: skyBlue)));
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: -10, right: -10,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // NUEVO SELECTOR DE FECHAS ELEGANTE Y COMPACTO
  void _showCustomDateRangePicker() {
    DateTime focusedDay = _startDate ?? DateTime.now();
    DateTime? rangeStart = _startDate;
    DateTime? rangeEnd = _endDate;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seleccionar Fechas',
                      style: TextStyle(color: skyBlue, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      locale: 'es_ES',
                      firstDay: DateTime(2023),
                      lastDay: DateTime(2030),
                      focusedDay: focusedDay,
                      rangeStartDay: rangeStart,
                      rangeEndDay: rangeEnd,
                      rangeSelectionMode: RangeSelectionMode.toggledOn,
                      onRangeSelected: (start, end, focused) {
                        setDialogState(() {
                          rangeStart = start;
                          rangeEnd = end;
                          focusedDay = focused;
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: skyBlue, fontSize: 16),
                        leftChevronIcon: Icon(Icons.chevron_left, color: skyBlue),
                        rightChevronIcon: Icon(Icons.chevron_right, color: skyBlue),
                      ),
                      calendarStyle: CalendarStyle(
                        rangeHighlightColor: skyBlue.withOpacity(0.2),
                        rangeStartDecoration: const BoxDecoration(color: skyBlue, shape: BoxShape.circle),
                        rangeEndDecoration: const BoxDecoration(color: skyBlue, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: skyBlue)),
                        todayTextStyle: const TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
                        selectedDecoration: const BoxDecoration(color: skyBlue, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: skyBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _startDate = rangeStart;
                              if (rangeEnd != null) {
                                _endDate = DateTime(rangeEnd!.year, rangeEnd!.month, rangeEnd!.day, 23, 59, 59);
                              } else if (rangeStart != null) {
                                _endDate = DateTime(rangeStart!.year, rangeStart!.month, rangeStart!.day, 23, 59, 59);
                              } else {
                                _endDate = null;
                              }
                              if (_startDate != null) _currentFilter = 'Rango';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteAppointment(String docId, String receiptUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: skyBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Eliminar Cita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('¿Estás seguro que deseas eliminar este comprobante/cita? Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('pagos').doc(docId).delete();
        if (receiptUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(receiptUrl).delete();
          } catch (e) {
            debugPrint('No se pudo borrar imagen en storage: $e');
          }
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante eliminado exitosamente'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _setFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      if (filter != 'Rango') {
        _startDate = null;
        _endDate = null;
      }
    });
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
      body: Column(
        children: [
          // BARRA DE FILTROS ELEGANTE (CHIPS DE CRISTAL)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Todas'),
                _buildFilterChip('Próximas'),
                _buildFilterChip('Pasadas'),
                _buildDateRangeChip(),
              ],
            ),
          ),

          // LISTA DE CITAS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pagos').where('patientId', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                if (snapshot.hasError) return const Center(child: Text('Ocurrió un error al cargar tus citas.', style: TextStyle(color: Colors.white)));

                final allAppointments = snapshot.data?.docs ?? [];

                // Aplicar filtros en memoria
                final now = DateTime.now();
                final filteredAppointments = allAppointments.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['appointmentDate'] as Timestamp?)?.toDate();
                  if (date == null) return false;

                  if (_currentFilter == 'Próximas') return date.isAfter(now);
                  if (_currentFilter == 'Pasadas') return date.isBefore(now);
                  if (_currentFilter == 'Rango' && _startDate != null && _endDate != null) {
                    return date.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
                        date.isBefore(_endDate!.add(const Duration(seconds: 1)));
                  }
                  return true; // 'Todas'
                }).toList();

                if (filteredAppointments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 80, color: Colors.white54),
                        SizedBox(height: 16),
                        Text('No se encontraron citas.', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(context, filteredAppointments[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // CHIP DE TEXTO NORMAL
  Widget _buildFilterChip(String label) {
    final isSelected = _currentFilter == label;
    return GestureDetector(
      onTap: () => _setFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.3), width: 1),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? skyBlue : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // CHIP DE FECHAS (CON ICONO Y BOTON CERRAR)
  Widget _buildDateRangeChip() {
    final isSelected = _currentFilter == 'Rango';
    final text = _startDate != null && _endDate != null
        ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
        : 'Fechas';

    return GestureDetector(
      onTap: _showCustomDateRangePicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.3), width: 1),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 16, color: isSelected ? skyBlue : Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? skyBlue : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _setFilter('Todas'),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: skyBlue.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: skyBlue),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: statusInfo['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    // BOTÓN DE ELIMINAR CITA
                    GestureDetector(
                      onTap: () => _deleteAppointment(doc.id, receiptUrl),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      ),
                    ),
                  ],
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
// 4. AYUDA Y SOPORTE
//==============================================================================

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUrl = Uri.parse("https://wa.me/593979072591?text=Hola,%20necesito%20ayuda%20con%20la%20aplicación.");
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al abrir WhatsApp.'), backgroundColor: Colors.red));
    }
  }

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _launchWhatsApp(context),
        backgroundColor: const Color(0xFF25D366),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 34),
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
              Text('+593 97 907 2591', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}