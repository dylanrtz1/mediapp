import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import 'home_screen.dart';

const Color kPrimaryColor = Color(0xFF00A9FF);
const Color kLightBlueColor = Color(0xFF33CFFF);
const Color kWhiteColor = Colors.white;
const Color kDarkTextColor = Color(0xFF3A3A3A);
const Color kGreyTextColor = Color(0xFF888888);

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kLightBlueColor, kPrimaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBubblesBackground(),
          child,
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: child,
      ),
    );
  }
}

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String _selectedTab = 'Sobre mí';

  @override
  void initState() {
    super.initState();
    if (widget.doctor.videoUrl.isNotEmpty) {
      _initVideoPlayer(widget.doctor.videoUrl);
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    try {
      final uri = Uri.parse(url);
      _videoController = VideoPlayerController.networkUrl(uri);
      await _videoController!.initialize();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
        _videoController?.setLooping(true);
        _videoController?.play();
      }
    } catch (e) {
      debugPrint('Error video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _navigateToServices() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ServicesScreen(doctor: widget.doctor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      widget.doctor.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kWhiteColor,
                        shadows: [Shadow(blurRadius: 5, color: Colors.black26)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildCredentialsSection(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildTabSelector(),
                  const SizedBox(height: 10),
                  _buildDynamicContent(),
                  const SizedBox(height: 20),
                  CaseGalleryGrid(images: widget.doctor.beforeAndAfterImageUrls),
                  const SizedBox(height: 20),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    const double kAvatarRadius = 55.0;
    const double kAvatarOverlap = 35.0;

    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: kPrimaryColor,
      elevation: 0,
      leading: const BackButton(color: kWhiteColor),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideoInitialized && _videoController != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              Image.network(
                widget.doctor.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: kPrimaryColor),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    kLightBlueColor.withOpacity(0.5),
                    kLightBlueColor,
                  ],
                  stops: const [0.0, 0.4, 0.9, 1.0],
                ),
              ),
            ),
            if (_isVideoInitialized && _videoController != null)
              Center(
                child: IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  color: Colors.white.withOpacity(0.85),
                  iconSize: 60,
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kAvatarRadius + kAvatarOverlap),
        child: SizedBox(
          height: kAvatarRadius + kAvatarOverlap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -kAvatarOverlap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.30),
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          width: kAvatarRadius * 2,
                          height: kAvatarRadius * 2,
                          color: Colors.white.withOpacity(0.40),
                          child: Image.network(
                            widget.doctor.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              widget.doctor.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'MSP: ${widget.doctor.mspRegistrationNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Text('•', style: TextStyle(color: Colors.white70)),
              Text(
                'SENESCYT: ${widget.doctor.senescytRegistrationNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          count: '${widget.doctor.yearsOfExperience}+',
          label: 'Años de Exp.',
        ),
        _buildStatItem(
          count: '${widget.doctor.casesPerformed}',
          label: 'Casos Realizados',
        ),
        _buildStatItem(
          count: widget.doctor.rating.toStringAsFixed(1),
          label: 'Puntuación',
        ),
      ],
    );
  }

  Widget _buildStatItem({required String count, required String label}) {
    return Flexible(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: kWhiteColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: kWhiteColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _buildTabButton(
            text: "Sobre mí",
            isSelected: _selectedTab == 'Sobre mí',
            onPressed: () => setState(() => _selectedTab = 'Sobre mí'),
          ),
          const SizedBox(width: 10),
          _buildTabButton(
            text: "Cursos",
            isSelected: _selectedTab == 'Cursos',
            onPressed: () => setState(() => _selectedTab = 'Cursos'),
          ),
          const SizedBox(width: 10),
          _buildTabButton(
            text: "Servicios",
            isSelected: false,
            onPressed: _navigateToServices,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.15),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: Colors.white.withOpacity(0.6),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedTab == 'Sobre mí'
          ? GlassCard(
          key: const ValueKey('about'),
          child: Text(
              widget.doctor.about.isNotEmpty ? widget.doctor.about : 'Biografía no disponible.',
              style: const TextStyle(color: Colors.white, height: 1.5, shadows: [Shadow(color: Colors.black26, blurRadius: 2)])
          )
      )
          : _buildCoursesContent(),
    );
  }

  Widget _buildCoursesContent() {
    if (widget.doctor.courses.isEmpty) {
      return GlassCard(
        key: const ValueKey('no_courses'),
        child: const SizedBox(
          height: 100,
          child: Center(
            child: Text('No hay cursos disponibles por el momento.', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    return GlassCard(
      key: const ValueKey('courses'),
      child: Column(
        children: widget.doctor.courses.map((course) {
          return ListTile(
            leading: const Icon(Icons.school, color: Colors.white),
            title: Text(course['title'] ?? 'Sin Título', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () {
              if (course['videoUrl'] != null && course['videoUrl'].isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CoursePlayerScreen(videoUrl: course['videoUrl'], title: course['title'])));
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Copyright ${DateTime.now().year} Cirugías de Lujo\nTodos los derechos reservados',
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
    );
  }
}

// -----------------------------------------------------------------------------
// MEJORAS APLICADAS A LA GALERIA DE CASOS (ANTES Y DESPUÉS)
// -----------------------------------------------------------------------------
class CaseGalleryGrid extends StatelessWidget {
  final List<dynamic> images;
  const CaseGalleryGrid({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Galería de Casos",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300, // Fuente más fina para mayor elegancia
              color: kWhiteColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "ANTES Y DESPUÉS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: kWhiteColor.withOpacity(0.8),
              letterSpacing: 4.0, // Letras espaciadas para un toque premium
            ),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageData = images[index];
              final beforeImage = (imageData is Map ? imageData['before'] : '') as String? ?? '';
              final afterImage = (imageData is Map ? imageData['after'] : '') as String? ?? '';
              final caseName = imageData is Map ? imageData['name'] ?? "Paciente ${index + 1}" : "Paciente ${index + 1}";

              return _buildGalleryItem(context, beforeImage, afterImage, caseName);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(BuildContext context, String beforeUrl, String afterUrl, String name) {
    // Mostramos una sola imagen como portada (priorizamos el resultado 'antes')
    final displayUrl = beforeUrl.isNotEmpty ? beforeUrl : afterUrl;

    return GestureDetector(
      onTap: () {
        // Al dar clic, mandamos las dos fotos al visor deslizable
        _openImageViewer(context, beforeUrl, afterUrl, name);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Vista de una sola imagen sin línea divisoria
            displayUrl.isNotEmpty
                ? Image.network(displayUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300))
                : Container(color: Colors.grey.shade300),

            // Gradiente elegante y sutil en la parte inferior para resaltar el texto
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4, right: 4),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    )
                ),
                child: Text(
                  name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kWhiteColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String beforeUrl, String afterUrl, String name) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Cambiado a transparente para lucir las burbujas
      barrierDismissible: false,
      useSafeArea: false,
      builder: (context) {
        return BeforeAfterViewer(
          beforeUrl: beforeUrl,
          afterUrl: afterUrl,
          name: name,
        );
      },
    );
  }
}

// NUEVO WIDGET para controlar el Swipe de Antes a Después
class BeforeAfterViewer extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;
  final String name;

  const BeforeAfterViewer({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    required this.name,
  });

  @override
  State<BeforeAfterViewer> createState() => _BeforeAfterViewerState();
}

class _BeforeAfterViewerState extends State<BeforeAfterViewer> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground( // Aplicamos el fondo de burbujas animadas aquí
        child: Stack(
          children: [
            // Visualizador deslizable
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                _buildPage(widget.beforeUrl),
                _buildPage(widget.afterUrl),
              ],
            ),

            // Textos e Indicadores (Arriba)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    widget.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentIndex == 0 ? "ANTES" : "DESPUÉS",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Indicador de Swipe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios, color: _currentIndex == 1 ? kWhiteColor : Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      const Text("Desliza", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, color: _currentIndex == 0 ? kWhiteColor : Colors.white38, size: 16),
                    ],
                  )
                ],
              ),
            ),

            // Botón Cerrar (Arriba Derecha)
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(String url) {
    if (url.isEmpty) {
      return const Center(child: Text('Imagen no disponible', style: TextStyle(color: Colors.white)));
    }
    return Padding(
      // Márgenes estrictos para asegurar que el fondo de burbujas SIEMPRE se vea
      padding: const EdgeInsets.only(top: 160.0, bottom: 80.0, left: 24.0, right: 24.0),
      child: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Cambiado a efecto vidrio (transparente)
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.5),
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain, // Mantiene la imagen completa sin recortar nada importante
                errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------

class ServicesScreen extends StatefulWidget {
  final Doctor doctor;
  const ServicesScreen({super.key, required this.doctor});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final Map<String, int> _selectedServices = {};

  void _updateServiceQuantity(String serviceId, int change) {
    setState(() {
      _selectedServices.update(serviceId, (value) => value + change, ifAbsent: () => 1);
      if (_selectedServices[serviceId]! <= 0) {
        _selectedServices.remove(serviceId);
      }
    });
  }

  void _navigateToCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CartScreen(
          doctor: widget.doctor,
          selectedServices: _selectedServices,
          onServicesUpdated: (updatedServices) {
            setState(() {
              _selectedServices.clear();
              _selectedServices.addAll(updatedServices);
            });
          },
        ),
      ),
    );
  }

  int get _totalItemsInCart => _selectedServices.values.fold(0, (sum, item) => sum + item);

  double _calculateCartTotal() {
    double total = 0.0;
    for (var entry in _selectedServices.entries) {
      final service = widget.doctor.services.firstWhere((s) => s['id'] == entry.key, orElse: () => {});
      if (service.isNotEmpty) {
        total += (service['priceWithApp'] as num? ?? 0.0) * entry.value;
      }
    }
    return total;
  }

  void _showAppointmentScheduler() {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añade al menos un servicio para agendar.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppointmentSchedulerModal(
        doctorId: widget.doctor.authUid,
        onDateTimeSelected: (dateTime) {
          Navigator.pop(context);
          _showPaymentOptions(dateTime);
        },
      ),
    );
  }

  void _showPaymentOptions(DateTime appointmentDate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentOptionsScreen(
          doctor: widget.doctor,
          totalAmount: _calculateCartTotal(),
          appointmentDate: appointmentDate,
          selectedServices: _selectedServices,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kLightBlueColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhiteColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 28, color: kWhiteColor),
                onPressed: _navigateToCart,
              ),
              if (_totalItemsInCart > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_totalItemsInCart', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 15, right: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: const Text(
                      'Servicios',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 30),
                    ),
                  ),
                  const Text(
                    'Todos nuestros tratamientos',
                    style: TextStyle(color: kWhiteColor, fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.doctor.services.length,
                itemBuilder: (context, index) {
                  final service = widget.doctor.services[index];
                  service['id'] ??= 'service_${index}_${service['name']}';
                  return _buildServiceItem(service);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBookingBar(),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final serviceId = service['id'] as String;
    final name = (service['name'] ?? 'Servicio').toString();
    final desc = (service['description'] ?? '').toString();
    final price = (service['priceWithApp'] as num? ?? 0.0).toDouble();
    final imageUrl = (service['image'] ?? '').toString();

    final int quantity = _selectedServices[serviceId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: () {
            _updateServiceQuantity(serviceId, 1);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name: +1 (Total: ${quantity + 1})'),
                duration: const Duration(seconds: 1),
                backgroundColor: kDarkTextColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (quantity > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.5),
                                ),
                                child: Text(
                                  'x$quantity',
                                  style: const TextStyle(
                                    color: kWhiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.5),
                            ),
                            child: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Precio App", style: TextStyle(color: kGreyTextColor, fontSize: 12)),
              Text(
                '\$${_calculateCartTotal().toStringAsFixed(2)}',
                style: const TextStyle(color: kDarkTextColor, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text("Agendar y Pagar"),
            onPressed: _showAppointmentScheduler,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhiteColor,
              elevation: 4,
              shadowColor: kPrimaryColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  final Doctor doctor;
  final Map<String, int> selectedServices;
  final Function(Map<String, int>) onServicesUpdated;

  const CartScreen({super.key, required this.doctor, required this.selectedServices, required this.onServicesUpdated});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, int> _currentSelectedServices;

  @override
  void initState() {
    super.initState();
    _currentSelectedServices = Map.from(widget.selectedServices);
  }

  void _updateServiceQuantity(String serviceId, int change) {
    setState(() {
      _currentSelectedServices.update(serviceId, (value) => value + change, ifAbsent: () => change);
      if (_currentSelectedServices[serviceId]! <= 0) {
        _currentSelectedServices.remove(serviceId);
      }
      widget.onServicesUpdated(_currentSelectedServices);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> servicesInCart = [];
    for (var serviceData in widget.doctor.services) {
      final serviceId = serviceData['id'] as String? ?? '';
      if (_currentSelectedServices.containsKey(serviceId)) {
        final quantity = _currentSelectedServices[serviceId]!;
        servicesInCart.add({...serviceData, 'quantity': quantity});
      }
    }

    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: const Text('Tu Carrito', style: TextStyle(color: kWhiteColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: GradientBackground(
        child: servicesInCart.isEmpty
            ? Center(child: Text('Tu carrito está vacío.', style: TextStyle(fontSize: 18, color: kWhiteColor.withOpacity(0.8))))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: servicesInCart.length,
          itemBuilder: (context, index) {
            final service = servicesInCart[index];
            final serviceId = service['id'] as String;
            return _buildCartItem(service, serviceId);
          },
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> service, String serviceId) {
    final name = service['name'] ?? 'Servicio';
    final priceApp = (service['priceWithApp'] as num? ?? 0.0).toDouble();
    final quantity = service['quantity'] as int;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text('\$${priceApp.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white70), onPressed: () => _updateServiceQuantity(serviceId, -1)),
              Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: () => _updateServiceQuantity(serviceId, 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentOptionsScreen extends StatelessWidget {
  final Doctor doctor;
  final double totalAmount;
  final DateTime appointmentDate;
  final Map<String, int> selectedServices;

  const PaymentOptionsScreen({
    super.key,
    required this.doctor,
    required this.totalAmount,
    required this.appointmentDate,
    required this.selectedServices,
  });

  void _navigateToBilling(BuildContext context, PaymentMethod method) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BillingDetailsScreen(
          doctor: doctor,
          totalAmount: totalAmount,
          appointmentDate: appointmentDate,
          selectedServices: selectedServices,
          paymentMethod: method,
        ),
      ),
    );
  }

  void _showBankAccounts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BankAccountViewer(
          accounts: doctor.bankAccounts,
          onProceed: () {
            Navigator.pop(context);
            _navigateToBilling(context, PaymentMethod.transfer);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPayWithCard = doctor.paymentLink.isNotEmpty;
    final hasBankAccounts = doctor.bankAccounts.isNotEmpty;

    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: const Text('Métodos de Pago', style: TextStyle(color: kWhiteColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                decoration: const BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL A PAGAR',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 25,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 60,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'PAGO MÍNIMO \$50',
                        style: TextStyle(
                          color: kPrimaryColor.withOpacity(0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Center(
                child: Text(
                  'MÉTODOS DE PAGO',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _PillButton(
                onTap: hasBankAccounts ? () => _showBankAccounts(context) : null,
                child: Column(
                  children: const [
                    Text(
                      'TRÁNSFERENCIAS\nBANCARIAS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'PAGO TOTAL / ABONO MÍNIMO \$50',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kGreyTextColor, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PillButton(
                onTap: canPayWithCard ? () => _navigateToBilling(context, PaymentMethod.card) : null,
                child: Column(
                  children: [
                    const Text(
                      'TARJETAS DE CRÉDITO O DÉBITO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/pago.jpeg',
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PAGO TOTAL',
                      style: TextStyle(
                        color: kGreyTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PillButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: enabled ? kWhiteColor : kWhiteColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

enum PaymentMethod { transfer, card }

class BillingDetailsScreen extends StatefulWidget {
  final Doctor doctor;
  final double totalAmount;
  final DateTime appointmentDate;
  final Map<String, int> selectedServices;
  final PaymentMethod paymentMethod;

  const BillingDetailsScreen({
    super.key,
    required this.doctor,
    required this.totalAmount,
    required this.appointmentDate,
    required this.selectedServices,
    required this.paymentMethod,
  });

  @override
  State<BillingDetailsScreen> createState() => _BillingDetailsScreenState();
}

class _BillingDetailsScreenState extends State<BillingDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _rucController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _receiptImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _receiptImage = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Debes iniciar sesión para completar la acción.')));
      return;
    }

    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, adjunta el comprobante de pago.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? receiptUrl;
      if (_receiptImage != null) {
        final ref = FirebaseStorage.instance.ref().child('comprobantes_pago').child('${DateTime.now().millisecondsSinceEpoch}-${_receiptImage!.path.split('/').last}');
        await ref.putFile(_receiptImage!);
        receiptUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('pagos').add({
        'patientId': user.uid,
        'patientName': '${_nameController.text} ${_lastNameController.text}',
        'patientEmail': _emailController.text,
        'patientPhone': _phoneController.text,
        'patientIdCard': _idController.text,
        'patientRuc': _rucController.text,
        'doctorId': widget.doctor.authUid,
        'doctorName': widget.doctor.name,
        'totalAmount': widget.totalAmount,
        'appointmentDate': widget.appointmentDate,
        'services': widget.selectedServices.entries.map((e) => {'id': e.key, 'quantity': e.value}).toList(),
        'paymentMethod': widget.paymentMethod.name,
        'receiptUrl': receiptUrl,
        'status': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text('Éxito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Tus datos y comprobante están siendo revisados. Puedes revisar tu sección "Mis Citas" para ver el estado de tu cita.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Entendido'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ocurrió un error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kWhiteColor, width: 3),
              ),
              child: const Icon(Icons.arrow_back, color: kWhiteColor, size: 28),
            ),
          ),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo2.png',
                  height: 130,
                  fit: BoxFit.contain,
                  color: kWhiteColor,
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          'DATOS DE FACTURACIÓN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _pillTextField(controller: _nameController, hint: 'NOMBRES', keyboardType: TextInputType.name, filledBlue: true, validator: (v) { if (v == null || v.isEmpty) return 'Campo requerido'; return null; }),
                        const SizedBox(height: 14),
                        _pillTextField(controller: _lastNameController, hint: 'APELLIDOS', keyboardType: TextInputType.name, filledBlue: false, validator: (v) { if (v == null || v.isEmpty) return 'Campo requerido'; return null; }),
                        const SizedBox(height: 14),
                        _pillTextField(controller: _idController, hint: 'CÉDULA DE IDENTIDAD / RUC', keyboardType: TextInputType.number, filledBlue: true, validator: (v) { if (v == null || v.isEmpty) return 'Campo requerido'; return null; }),
                        const SizedBox(height: 14),
                        _pillTextField(controller: _emailController, hint: 'CORREO ELECTRÓNICO', keyboardType: TextInputType.emailAddress, filledBlue: false, validator: (v) { if (v == null || v.isEmpty) return 'Campo requerido'; return null; }),
                        const SizedBox(height: 14),
                        _pillTextField(controller: _phoneController, hint: 'TELÉFONO', keyboardType: TextInputType.phone, filledBlue: true, validator: (v) { if (v == null || v.isEmpty) return 'Campo requerido'; return null; }),
                        const SizedBox(height: 14),
                        _pillTextField(controller: _rucController, hint: 'RUC (OPCIONAL)', keyboardType: TextInputType.number, filledBlue: false, isOptional: true, validator: (_) => null),
                        const SizedBox(height: 22),
                        if (widget.paymentMethod == PaymentMethod.card) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                const Text(
                                  "Serás redirigido a la web para completar el pago. Luego, regresa y adjunta el comprobante.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: kDarkTextColor, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () async {
                                    final url = Uri.parse(widget.doctor.paymentLink.trim());
                                    if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    foregroundColor: kWhiteColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                  child: const Text('Proceder a Pagar en la Web', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: Text(_receiptImage == null ? 'ADJUNTAR COMPROBANTE' : 'COMPROBANTE CARGADO'),
                            onPressed: _pickImage,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kPrimaryColor, width: 3),
                              foregroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .6),
                            ),
                          ),
                        ),
                        if (_receiptImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _receiptImage!.path.split('/').last,
                              style: const TextStyle(color: kGreyTextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kPrimaryColor, width: 3),
                              foregroundColor: kPrimaryColor,
                              backgroundColor: kWhiteColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Text(
                              _isLoading ? 'ENVIANDO...' : 'CONFIRMAR',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    required bool filledBlue,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    final hintBase = TextStyle(
      color: filledBlue ? kWhiteColor : kPrimaryColor,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      fontSize: 16,
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: filledBlue ? kWhiteColor : kDarkTextColor,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      decoration: _pillDecoration(hint, filledBlue: filledBlue, hintStyle: hintBase),
    );
  }

  InputDecoration _pillDecoration(
      String hint, {
        required bool filledBlue,
        TextStyle? hintStyle,
      }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: kPrimaryColor, width: 3),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      filled: true,
      fillColor: filledBlue ? kPrimaryColor : kWhiteColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      enabledBorder: filledBlue
          ? border.copyWith(borderSide: const BorderSide(color: Colors.transparent, width: 0))
          : border,
      focusedBorder: filledBlue
          ? border.copyWith(borderSide: const BorderSide(color: Colors.transparent, width: 0))
          : border,
    );
  }
}

class CoursePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  const CoursePlayerScreen({super.key, required this.videoUrl, required this.title});

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      if (mounted) setState(() { _initialized = true; _controller!.play(); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo cargar el video del curso."), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: kWhiteColor)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _initialized && _controller != null
            ? AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: GestureDetector(
            onTap: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()),
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller!),
                AnimatedOpacity(
                  opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.play_arrow, color: kWhiteColor, size: 80),
                ),
              ],
            ),
          ),
        )
            : const CircularProgressIndicator(color: kWhiteColor),
      ),
    );
  }
}

class AppointmentSchedulerModal extends StatefulWidget {
  final String doctorId;
  final Function(DateTime) onDateTimeSelected;
  const AppointmentSchedulerModal({super.key, required this.onDateTimeSelected, required this.doctorId});

  @override
  State<AppointmentSchedulerModal> createState() => _AppointmentSchedulerModalState();
}

class _AppointmentSchedulerModalState extends State<AppointmentSchedulerModal> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;

  final List<TimeOfDay> _availableTimes = const [
    TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 16, minute: 0),
  ];

  List<DateTime> _bookedSlots = [];
  bool _isLoadingTimes = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchBookedSlots(_focusedDay);
  }

  Future<void> _fetchBookedSlots(DateTime day) async {
    setState(() {
      _isLoadingTimes = true;
      _selectedTime = null;
      _bookedSlots = [];
    });

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pagos')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('appointmentDate', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDate', isLessThan: endOfDay)
          .get();

      final approvedDocs = snapshot.docs.where((doc) {
        final status = doc['status'] as String? ?? 'pendiente';
        return status == 'aprobado';
      });

      final bookedAppointments = approvedDocs.map((doc) {
        final timestamp = doc['appointmentDate'] as Timestamp;
        return timestamp.toDate();
      }).toList();

      if (mounted) {
        setState(() {
          _bookedSlots = bookedAppointments;
          _isLoadingTimes = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando citas ocupadas: $e');
      if (mounted) {
        setState(() => _isLoadingTimes = false);
      }
    }
  }

  bool _isSlotBooked(TimeOfDay time) {
    if (_selectedDay == null) return false;
    final now = DateTime.now();
    final slotDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      time.hour,
      time.minute,
    );
    if (slotDateTime.isBefore(now)) {
      return true;
    }
    return _bookedSlots.any((booked) => booked.hour == slotDateTime.hour && booked.minute == slotDateTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhiteColor, size: 24),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'AGENDAMIENTO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kWhiteColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSlide(
                offset: const Offset(0, 0.05),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      locale: 'es_ES',
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) {
                        if (!isSameDay(_selectedDay, selected)) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                          _fetchBookedSlots(selected);
                        }
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date).toUpperCase(),
                        titleTextStyle: const TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                        leftChevronIcon: const Icon(Icons.chevron_left, color: kPrimaryColor),
                        rightChevronIcon: const Icon(Icons.chevron_right, color: kPrimaryColor),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(color: kDarkTextColor),
                        weekendTextStyle: TextStyle(color: kDarkTextColor.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Seleccione una hora:',
                style: TextStyle(
                  color: kWhiteColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoadingTimes)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  ),
                )
              else
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: _availableTimes.map((time) {
                    final isBooked = _isSlotBooked(time);
                    final isSelected = _selectedTime == time;
                    return ChoiceChip(
                      label: Text(
                        time.format(context),
                        style: TextStyle(
                          color: isBooked ? Colors.grey.shade400 : (isSelected ? kWhiteColor : kDarkTextColor),
                          decoration: isBooked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: isBooked ? null : (selected) => setState(() => _selectedTime = selected ? time : null),
                      selectedColor: kPrimaryColor,
                      disabledColor: Colors.grey.shade200,
                      backgroundColor: kWhiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_selectedDay != null && _selectedTime != null)
                    ? () {
                  final finalDateTime = DateTime(
                    _selectedDay!.year,
                    _selectedDay!.month,
                    _selectedDay!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                  );
                  widget.onDateTimeSelected(finalDateTime);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWhiteColor,
                  foregroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  disabledBackgroundColor: kWhiteColor.withOpacity(.6),
                  disabledForegroundColor: kPrimaryColor.withOpacity(.6),
                ),
                child: const Text('PAGAR'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Si por algún motivo el médico no pudiera asistir en la fecha prevista, '
                    'la cita se podrá reprogramar sin problema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline, color: kPrimaryColor, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las fechas pueden variar según la disponibilidad del médico.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class BankCardStyle {
  final LinearGradient gradient;
  final Color shadowColor;
  BankCardStyle({required this.gradient, required this.shadowColor});
}

class BankAccountViewer extends StatefulWidget {
  final List<BankAccount> accounts;
  final VoidCallback onProceed;
  const BankAccountViewer({super.key, required this.accounts, required this.onProceed});

  @override
  State<BankAccountViewer> createState() => _BankAccountViewerState();
}

class _BankAccountViewerState extends State<BankAccountViewer> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  BankCardStyle _getBankStyle(String bankName) {
    final name = bankName.toLowerCase();

    if (name.contains('guayaquil')) {
      return BankCardStyle(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE5007E),
            Color(0xFFC4006A),
            Color(0xFF0057B8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFFE5007E),
      );
    } else if (name.contains('pichincha')) {
      return BankCardStyle(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFDD00),
            Color(0xFFFBC400),
          ],
          stops: [0.0, 0.6],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFFFFDD00),
      );
    } else if (name.contains('produbanco')) {
      return BankCardStyle(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF43A047),
      );

    } else if (name.contains('pacifico') || name.contains('pacífico')) {
      return BankCardStyle(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00B5E2),
            Color(0xFF0099D8),
            Color(0xFF005B96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF00B5E2),
      );
    } else if (name.contains('bolivariano')) {
      return BankCardStyle(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF47D7E8),
            Color(0xFF27BFD0),
            Color(0xFF0F8FA5),
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF27BFD0),
      );
    }

    return BankCardStyle(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF455A64),
          Color(0xFF37474F),
          Color(0xFF263238),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: Colors.black54,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          )),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Text('Datos para Transferencia', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.accounts.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) => _buildBankAccountCard(widget.accounts[index]),
                  ),
                ),
                if (widget.accounts.length > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.accounts.length, (index) => _buildIndicator(index == _currentPage)),
                  ),
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Adjuntar Comprobante'),
                    onPressed: widget.onProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kWhiteColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(BankAccount account) {
    final style = _getBankStyle(account.bankName);
    final bankNameLower = account.bankName.toLowerCase();
    String? logoAsset;

    if (bankNameLower.contains('guayaquil')) {
      logoAsset = 'assets/images/guaya.png';
    } else if (bankNameLower.contains('pichincha')) {
      logoAsset = 'assets/images/pichi.png';
    } else if (bankNameLower.contains('pacifico') || bankNameLower.contains('pacífico')) {
      logoAsset = 'assets/images/paci.png';
    } else if (bankNameLower.contains('produbanco')) {
      logoAsset = 'assets/images/produ.png';
    } else if (bankNameLower.contains('bolivariano')) {
      logoAsset = 'assets/images/boli.png';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: style.gradient,
        boxShadow: [
          BoxShadow(
            color: style.shadowColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: _decorativeCircle(Colors.white.withOpacity(0.1), 150)),
          Positioned(bottom: -40, left: -20, child: _decorativeCircle(Colors.white.withOpacity(0.1), 120)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: logoAsset != null
                          ? Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          logoAsset,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                account.bankName.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                                maxLines: 1,
                              ),
                            );
                          },
                        ),
                      )
                          : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account.bankName.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const Icon(Icons.contactless_outlined, color: Colors.white70, size: 32),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 45,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8CA72), Color(0xFFFDE08B), Color(0xFFE8CA72)],
                    ),
                    border: Border.all(color: Colors.black26, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(width: 1, color: Colors.black12),
                      Container(width: 1, color: Colors.black12),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account.accountNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Courier',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy, color: Colors.white, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: account.accountNumber));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Número de cuenta copiado'), duration: Duration(seconds: 1)));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TITULAR',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, letterSpacing: 1),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              account.beneficiaryName.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'C.I. / RUC',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, letterSpacing: 1),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              account.beneficiaryId,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: account.beneficiaryId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cédula/RUC copiada'), duration: Duration(seconds: 1)),
                                );
                              },
                              child: const Icon(Icons.copy, size: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? kPrimaryColor : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}