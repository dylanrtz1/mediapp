import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Agregado: Para actualizar la DB
import 'package:shared_preferences/shared_preferences.dart'; // Agregado: Para leer la selección
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _showPassword = false;

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryTextColor = Color(0xFF3A3A3A);

  late final AnimationController _backgroundAnimationController;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  // --- NUEVA LÓGICA DE ACTUALIZACIÓN ---
  // Esta función asegura que la ciudad elegida en Onboarding se guarde en el usuario
  Future<void> _updateUserCityInFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final selectedCity = prefs.getString('user_city');

      // Si hay una ciudad seleccionada en el dispositivo, actualizamos al usuario
      if (selectedCity != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(
            {'city': selectedCity},
            SetOptions(merge: true) // merge: true para no borrar otros datos
        );
      }
    } catch (e) {
      debugPrint("Error actualizando la ciudad del usuario: $e");
      // No interrumpimos el flujo si esto falla, pero queda registrado
    }
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // APLICAMOS LA ACTUALIZACIÓN DE CIUDAD AQUÍ
      await _updateUserCityInFirestore();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showFeedbackDialog(
          title: "Error al iniciar sesión",
          message: "Por favor, revisa tu correo o contraseña e intenta nuevamente.",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _socialLogin(Future<User?> Function() loginMethod) async {
    setState(() => _isLoading = true);
    try {
      await loginMethod();

      // APLICAMOS LA ACTUALIZACIÓN DE CIUDAD AQUÍ TAMBIÉN
      await _updateUserCityInFirestore();

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        _showFeedbackDialog(
          title: "Error de Autenticación",
          message: "Ocurrió un problema al intentar iniciar sesión con tu cuenta. Por favor, intenta nuevamente.",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() {
    if (_emailController.text.trim().isEmpty) {
      _showFeedbackDialog(
        title: 'Correo requerido',
        message: 'Ingresa tu correo en el campo superior para recuperar tu contraseña.',
        isError: true,
      );
      return;
    }

    _showFeedbackDialog(
      title: 'Restablecer Contraseña',
      message:
      'Se enviará un enlace de recuperación a:\n${_emailController.text.trim()}',
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.sendPasswordResetEmail(
                    _emailController.text.trim());
                if (mounted) {
                  _showFeedbackDialog(
                    title: 'Correo enviado',
                    message:
                    'Revisa tu bandeja de entrada o spam para continuar.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showFeedbackDialog(
                    title: 'Error',
                    message: "No se pudo enviar el correo. Verifica que la dirección sea correcta y vuelve a intentarlo.",
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Enviar'))
      ],
    );
  }

  void _showFeedbackDialog({
    required String title,
    required String message,
    bool isError = false,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : primaryBlue,
            ),
            const SizedBox(width: 10),
            // AQUÍ ESTÁ LA SOLUCIÓN: Agregamos Expanded para evitar el RenderFlex overflow
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: actions ??
            [
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar"))
            ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF00A9FF)),

          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    Image.asset(
                      'assets/images/logo2.png',
                      height: 130,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.medical_services, size: 100),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Bienvenido de vuelta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Inicia sesión para continuar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 36),

                    _buildTextField(
                        controller: _emailController,
                        label: "Correo Electrónico",
                        keyboardType: TextInputType.emailAddress),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordController,
                      label: "Contraseña",
                      isPassword: true,
                      showPassword: _showPassword,
                      onToggleVisibility: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _resetPassword,
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // BOTÓN LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "INICIAR SESIÓN",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    _buildDivider(),
                    const SizedBox(height: 26),

                    _buildSocialButtons(),

                    const SizedBox(height: 30),

                    // >>> LOGO mark.png CENTRADO <<<
                    Image.asset(
                      'assets/images/mark.png',
                      height: 55,
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "¿No tienes una cuenta?",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "© 2025 Cirugías de Lujo\nTodos los derechos reservados",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              blurRadius: 4,
                              color: Colors.black54)
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !showPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: primaryTextColor),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Este campo es obligatorio.";
        }
        if (label.contains("Correo") && !value.contains('@')) {
          return "Ingresa un correo válido.";
        }
        return null;
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Colors.white70)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o continuar con',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
        ),
        const Expanded(child: Divider(thickness: 1, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          icon: FontAwesomeIcons.google,
          color: Colors.red,
          onPressed: () => _socialLogin(_authService.signInWithGoogle),
        ),
        // Botón de Facebook comentado temporalmente a petición del usuario
        /*
        const SizedBox(width: 24),
        _buildSocialButton(
          icon: FontAwesomeIcons.facebook,
          color: Colors.blue.shade800,
          onPressed: () => _socialLogin(_authService.signInWithFacebook),
        ),
        */
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300)),
        child: FaIcon(icon, color: color, size: 23),
      ),
    );
  }
}