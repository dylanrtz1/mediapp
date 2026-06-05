import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  static const Color skyBlue = Color(0xFF29B6F6);
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  late final AnimationController _textController;
  late final VideoPlayerController _videoController;

  bool _videoReady = false;
  bool _videoError = false;

  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _initializeVideo();
    _loadSavedCity();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/images/onbovid.mp4')
      ..setLooping(true)
      ..setVolume(0.0);

    // Mantenemos el timeout por seguridad para que no congele la app en dispositivos conflictivos
    _videoController.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw Exception("El decodificador tardó demasiado en cargar el mp4.");
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _videoReady = true;
          _videoError = false;
        });
        _videoController.play();
      }
    }).catchError((error) {
      debugPrint("Error al inicializar video asset: $error");
      if (mounted) {
        setState(() {
          _videoReady = false;
          _videoError = true;
        });
      }
    });
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('user_city');
    if (!mounted) return;
    if (savedCity != null) {
      setState(() => _selectedCity = savedCity);
    }
  }

  Future<void> _confirmAndSelectCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_city', city);
    if (!mounted) return;
    setState(() => _selectedCity = city);
  }

  Future<void> _resetCitySelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_city');
    if (!mounted) return;
    setState(() => _selectedCity = null);
  }

  void _showCityConfirmationDialog(String city) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: skyBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Confirmar Ciudad',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Has seleccionado "$city" para tu atención.\n\n¿Deseas continuar con esta ciudad?',
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
                _confirmAndSelectCity(city);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: skyBlue,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInAnonymously();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en modo invitado: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gradiente de respaldo en caso de que el video no cargue a tiempo
    const fallbackGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF00A9FF),
        Color(0xFF0077C2),
        Colors.black,
      ],
      stops: [0.0, 0.5, 1.0],
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // CAPA 0: Fondo base / Fallback
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: fallbackGradient),
            ),
          ),

          // CAPA 1: Video mp4
          if (_videoReady && !_videoError && _videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          // CAPA 2: Overlay oscuro para asegurar legibilidad
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // CAPA 3: Contenido Principal
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(flex: 2),
                            // LOGO
                            Image.asset(
                              'assets/images/logo2.png',
                              height: 180,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.medical_services_outlined, size: 150, color: Colors.white),
                            ),
                            const SizedBox(height: 24),

                            // TEXTOS ANIMADOS
                            AnimatedBuilder(
                              animation: _textController,
                              builder: (context, _) {
                                final a1 = (_textController.value * 2.0) % 1.0;
                                final a2 = (_textController.value * 3.2) % 1.0;
                                return Column(
                                  children: [
                                    ShinyText(text: 'CIRUGÍAS DE LUJO', animation: a1, fontSize: 28, letterSpacing: 1.6, glowColor: skyBlue, strokeColor: const Color(0xFF0D47A1)),
                                    const SizedBox(height: 8),
                                    ShinySubtitleText(text: 'Tu belleza, nuestra especialidad.', animation: a2, fontSize: 17, glowColor: skyBlue),
                                  ],
                                );
                              },
                            ),

                            const Spacer(flex: 3),

                            // BOTONES DE ACCIÓN
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation), child: child)),
                              child: _buildActionWidgets(skyBlue),
                            ),

                            const SizedBox(height: 30),

                            // FOOTER
                            Text(
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
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // CAPA 4: Loading
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionWidgets(Color skyBlue) {
    if (_selectedCity == null) {
      return Column(
        key: const ValueKey('city_selection'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TextShadow(child: Text("Elige donde deseas tu atención:", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600))),
          const SizedBox(height: 20),
          _outlinedLight(buttonText: 'QUITO', onTap: () => _showCityConfirmationDialog('Quito'), color: skyBlue),
          const SizedBox(height: 16),
          _outlinedLight(buttonText: 'GUAYAQUIL', onTap: () => _showCityConfirmationDialog('Guayaquil'), color: skyBlue),
        ],
      );
    } else {
      return Column(
        key: const ValueKey('auth_buttons'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TextShadow(child: Text("Atención en: $_selectedCity", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w400))),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: skyBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 6),
            child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen(selectedCity: _selectedCity!))),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: skyBlue, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _signInAsGuest,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: skyBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Modo invitado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _resetCitySelection,
            icon: const Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
            label: const Text('Cambiar ciudad', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ],
      );
    }
  }

  Widget _outlinedLight({required String buttonText, required VoidCallback onTap, required Color color}) {
    return OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: color, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)));
  }
}

// --- CLASES ORIGINALES ---
class ShinyText extends StatelessWidget {
  const ShinyText({
    super.key,
    required this.text,
    required this.animation,
    this.fontSize = 26,
    this.letterSpacing = 1.5,
    this.strokeColor = const Color(0xFF0D47A1),
    this.fillBaseColor = Colors.white,
    this.glowColor = const Color(0xFF29B6F6),
  });

  final String text;
  final double animation;
  final double fontSize;
  final double letterSpacing;
  final Color strokeColor;
  final Color fillBaseColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final glow = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(animation * 2 * math.pi));
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = strokeColor.withOpacity(0.95);

    final textStroke = Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            fontWeight: FontWeight.w900,
            foreground: strokePaint
        )
    );

    final textFill = _ShimmerFill(
        text: text,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        baseColor: fillBaseColor,
        animation: animation,
        glowColor: glowColor,
        shadows: [
          Shadow(blurRadius: 18 * glow, color: glowColor.withOpacity(0.80 * glow), offset: const Offset(0, 1)),
          const Shadow(blurRadius: 14, color: Colors.white70, offset: Offset(0, 0)),
          const Shadow(blurRadius: 6, color: Colors.black45, offset: Offset(0, 1))
        ]
    );

    return Stack(alignment: Alignment.center, children: [textStroke, textFill]);
  }
}

class ShinySubtitleText extends StatelessWidget {
  const ShinySubtitleText({
    super.key,
    required this.text,
    required this.animation,
    this.fontSize = 16,
    this.glowColor = const Color(0xFF29B6F6),
  });

  final String text;
  final double animation;
  final double fontSize;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF0B3D91).withOpacity(0.80);

    final stroke = Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            foreground: strokePaint
        )
    );

    final fill = _ShimmerFill(
        text: text,
        fontSize: fontSize,
        baseColor: Colors.white,
        animation: animation,
        letterSpacing: 0.4,
        glowColor: glowColor,
        shadows: const [
          Shadow(blurRadius: 10, color: Colors.white70, offset: Offset(0, 0)),
          Shadow(blurRadius: 6, color: Colors.black45, offset: Offset(0, 1))
        ]
    );

    return Stack(alignment: Alignment.center, children: [stroke, fill]);
  }
}

class _ShimmerFill extends StatelessWidget {
  const _ShimmerFill({
    required this.text,
    required this.fontSize,
    required this.animation,
    this.letterSpacing = 0.0,
    this.baseColor = Colors.white,
    this.shadows = const [],
    this.glowColor = const Color(0xFF29B6F6),
  });

  final String text;
  final double fontSize;
  final double animation;
  final double letterSpacing;
  final Color baseColor;
  final List<Shadow> shadows;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (Rect bounds) {
          final w = bounds.width;
          final h = bounds.height;
          final highlightWidth = w * 0.35;
          final dx = -highlightWidth + (w + highlightWidth * 2) * animation;
          final rect = Rect.fromLTWH(dx, 0, highlightWidth, h);
          final gradient = LinearGradient(
              colors: [
                const Color(0x00FFFFFF),
                const Color(0xFFEFFFFF),
                Colors.white,
                const Color(0xFFE0F7FA),
                const Color(0x00000000)
              ].map((c) => Color.alphaBlend(glowColor.withOpacity(0.22), c)).toList(),
              stops: const [0.0, 0.28, 0.50, 0.72, 1.0]
          );
          return gradient.createShader(rect);
        },
        child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: fontSize,
                letterSpacing: letterSpacing,
                fontWeight: FontWeight.w800,
                color: baseColor,
                shadows: shadows
            )
        )
    );
  }
}

class _TextShadow extends StatelessWidget {
  const _TextShadow({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (child is! Text) return child;
    final t = child as Text;
    final style = t.style ?? const TextStyle();
    return Text(
        t.data ?? '',
        textAlign: t.textAlign,
        maxLines: t.maxLines,
        overflow: t.overflow,
        style: style.copyWith(
            shadows: const [
              Shadow(blurRadius: 8, color: Colors.white60, offset: Offset(0, 0)),
              Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 1))
            ]
        )
    );
  }
}