import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/doctor_model.dart';
import '../widgets/drawer_and_screens.dart'; // Asegúrate de que este import sea correcto según tu estructura
import 'doctor_profile_screen.dart';
import 'doctors_by_category_screen.dart';
import '../auth/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Doctor> _allDoctors = [];
  bool _isLoading = true;
  bool _isGuest = false;

  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  List<Map<String, dynamic>> _promotions = [];
  VideoPlayerController? _videoController;
  String _quienesSomosVideoUrl = '';
  bool _isYouTubeVideo = false;
  bool _videoInitialized = false;
  StreamSubscription? _marketingSubscription;
  final TextEditingController _searchController = TextEditingController();

  static const double _fixedBarHeight = kToolbarHeight;
  static const double _footerHeight = 48;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _listenToMarketingData();
    _fetchDoctors();
    _startBannerTimer();
  }

  void _checkUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      setState(() => _isGuest = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _bannerTimer?.cancel();
    _marketingSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _listenToMarketingData() {
    final marketingDocRef = FirebaseFirestore.instance.collection('marketing').doc('settings');
    _marketingSubscription = marketingDocRef.snapshots().listen((docSnap) {
      if (mounted && docSnap.exists) {
        final data = docSnap.data()!;
        final newVideoUrl = data['aboutUsVideoUrl'] as String? ?? '';
        final newPromotions = List<Map<String, dynamic>>.from(data['promotions'] ?? []);
        if (newVideoUrl != _quienesSomosVideoUrl) {
          setState(() => _quienesSomosVideoUrl = newVideoUrl);
          _initVideoPlayer(_quienesSomosVideoUrl);
        }
        setState(() => _promotions = newPromotions);
      }
    }, onError: (error) {
      print("Error escuchando datos de marketing: $error");
    });
  }

  Future<void> _initVideoPlayer(String url) async {
    await _videoController?.dispose();
    _videoController = null;
    _isYouTubeVideo = false;
    _videoInitialized = false;
    if (url.isEmpty) { if (mounted) setState(() {}); return; }
    if (url.contains('youtube.com') || url.contains('youtu.be')) { if (mounted) setState(() => _isYouTubeVideo = true); return; }
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController?.initialize();
      await _videoController?.setLooping(true);
      if (mounted) setState(() => _videoInitialized = true);
    } catch (e) {
      print("Error inicializando el video: $e");
    }
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_promotions.isNotEmpty && mounted) {
        setState(() {
          _currentBannerPage = (_currentBannerPage + 1) % _promotions.length;
        });
      }
    });
  }

  Future<void> _fetchDoctors() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      final doctors = snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList();
      _allDoctors.clear();
      _allDoctors.addAll(doctors);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al cargar doctores: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE LIMPIEZA DE TEXTO (NORMALIZACIÓN) ---
  String _normalizeText(String text) {
    // 1. Convertir a minúsculas
    String str = text.toLowerCase();

    // 2. Mapa de caracteres a reemplazar (con tilde -> sin tilde, ñ -> n)
    const String withDiacritics = 'áéíóúüñ';
    const String withoutDiacritics = 'aeiouun';

    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }

    return str.trim();
  }

  void _performSearch(String query) {
    if (_isGuest) {
      _showGuestDialog();
      return;
    }

    if (query.trim().isEmpty) return;

    // Normalizamos lo que escribió el usuario (ej: "Bariátrica" -> "bariatrica")
    final cleanQuery = _normalizeText(query);

    final filteredDocs = _allDoctors.where((doc) {
      // Normalizamos los datos del doctor
      final cleanName = _normalizeText(doc.name);
      final cleanSpecialty = _normalizeText(doc.specialty);

      // Buscamos coincidencia en Nombre O Especialidad (Categoría)
      return cleanName.contains(cleanQuery) || cleanSpecialty.contains(cleanQuery);
    }).toList();

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DoctorsByCategoryScreen(
                specialtyTitle: "Resultados: ${query.trim()}",
                doctors: filteredDocs
            )
        )
    );
  }

  void _showGuestDialog() {
    const skyBlue = Color(0xFF29B6F6);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: skyBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Función Exclusiva',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Para acceder a esta y otras funciones, necesitas crear una cuenta o iniciar sesión.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showLogoutConfirmationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: skyBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Registrarse / Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    const skyBlue = Color(0xFF29B6F6);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: skyBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _isGuest ? 'Ir a Inicio' : 'Cerrar Sesión',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _isGuest ? 'Serás redirigido a la pantalla de bienvenida.' : '¿Estás seguro de que deseas cerrar sesión?',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleSignOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: skyBlue,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    await Future.delayed(const Duration(seconds: 2));
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _navigateToCategory(String specialty, String title) {
    if (_isGuest) {
      _showGuestDialog();
      return;
    }
    // Normalizamos también aquí para asegurar consistencia
    final cleanSpecialty = _normalizeText(specialty);

    final filteredDocs = _allDoctors.where((doctor) =>
    _normalizeText(doctor.specialty) == cleanSpecialty
    ).toList();

    Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorsByCategoryScreen(specialtyTitle: title, doctors: filteredDocs)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(isGuest: _isGuest, onSignOut: _showLogoutConfirmationDialog),
      backgroundColor: const Color(0xFF00A9FF),


      //  Footer fijo de verdad (no se desplaza ni tapa contenido)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: _footerHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Text(
            'Copyright 2025 Cirugías de Lujo\nTodos los derechos reservados',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          // Contenido scrollable SIN footer encima
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
            onRefresh: _fetchDoctors,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // espacio para la barra fija superior
                SizedBox(height: MediaQuery.of(context).padding.top + _fixedBarHeight),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 30),
                _buildSectionTitle('¿Quiénes Somos?'),
                const SizedBox(height: 16),
                _buildQuienesSomosVideo(),
                const SizedBox(height: 30),
                _buildSectionTitle('Servicios'),
                const SizedBox(height: 16),
                _buildCategories(),
                const SizedBox(height: 30),
                if (_promotions.isNotEmpty) ...[
                  _buildSectionTitle('Promociones'),
                  const SizedBox(height: 16),
                  _buildPromotionsBanner(),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),

          // AppBar fijo
          Positioned(top: 0, left: 0, right: 0, child: _buildFixedAppBar()),
        ],
      ),
    );
  }

  Widget _buildFixedAppBar() {
    return Builder(
      builder: (context) {
        return Container(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: _fixedBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      tooltip: 'Menú',
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _showLogoutConfirmationDialog,
                      tooltip: _isGuest ? 'Iniciar sesión' : 'Cerrar sesión',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Image.asset('assets/images/logo2.png', height: 120),
  );

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: _isGuest ? _showGuestDialog : null,
        child: AbsorbPointer(
          absorbing: _isGuest,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search, // Cambia el botón del teclado a "Buscar"
            decoration: InputDecoration(
              hintText: 'Buscar doctor o procedimiento...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            onSubmitted: (value) => _performSearch(value),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Text(
      title,
      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black45)]),
    ),
  );

  Widget _buildQuienesSomosVideo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Builder(builder: (context) {
            if (_quienesSomosVideoUrl.isEmpty) {
              return Container(color: Colors.grey.shade200, child: Center(child: Text('Video "Quiénes Somos" no configurado.', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center)));
            }
            if (_isYouTubeVideo) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.ondemand_video, color: Colors.white70, size: 60),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_quienesSomosVideoUrl.isNotEmpty) {
                          final url = Uri.parse(_quienesSomosVideoUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      icon: const Icon(FontAwesomeIcons.youtube, color: Colors.red),
                      label: const Text('Ver en YouTube'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    )
                  ]),
                ),
              );
            }
            if (_videoController != null && _videoInitialized) {
              return GestureDetector(
                onTap: () => setState(() { _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play(); }),
                child: Stack(alignment: Alignment.center, children: [
                  VideoPlayer(_videoController!),
                  AnimatedOpacity(opacity: _videoController!.value.isPlaying ? 0.0 : 1.0, duration: const Duration(milliseconds: 300), child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.8), size: 60))
                ]),
              );
            }
            return Container(color: Colors.grey.shade800, child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Colors.white, strokeWidth: 2), SizedBox(height: 10), Text('Cargando video...', style: TextStyle(color: Colors.white))])));
          }),
        ),
      ),
    );
  }

  Widget _buildCategories() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _buildCategoryButton('ODONTOLÓGICA', 'Odontología', 'assets/images/odon.png'),
      _buildCategoryButton('CIRUGÍA ESTÉTICA', 'Estética', 'assets/images/este.png'),
      _buildCategoryButton('CIRUGÍA BARIATRICA', 'Bariátrica', 'assets/images/bari.png')
    ]),
  );

  Widget _buildCategoryButton(String specialtyId, String title, String imagePath) {
    return GestureDetector(
      onTap: () => _navigateToCategory(specialtyId, title),
      child: Column(
        children: [
          // Borde blanco exterior limpio
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            // Imagen circular sin sombras ni degradados
            child: ClipOval(
              child: SizedBox(
                width: 84,
                height: 84,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsBanner() {
    if (_promotions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 150,
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 1),
        transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: child),
        child: _buildBannerPage(key: ValueKey<int>(_currentBannerPage), promo: _promotions[_currentBannerPage]),
      ),
    );
  }

  Widget _buildBannerPage({required Key key, required Map<String, dynamic> promo}) {
    final imageUrl = promo['imageUrl'] as String? ?? '';
    final linkUrl = promo['linkUrl'] as String? ?? '';
    return GestureDetector(
      key: key,
      onTap: () async {
        if (linkUrl.isNotEmpty) {
          final url = Uri.parse(linkUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade200,
          image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover, onError: (e, s) {}) : null,
        ),
        child: imageUrl.isEmpty ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)) : null,
      ),
    );
  }
}