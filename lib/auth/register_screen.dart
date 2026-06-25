import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import '../utils/background_painter.dart';

class RegisterScreen extends StatefulWidget {
  final String selectedCity;
  const RegisterScreen({super.key, required this.selectedCity});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _termsAccepted = false;

  late AnimationController _backgroundAnimationController;

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryTextColor = Color(0xFF3A3A3A);

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
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showFeedbackDialog(
        title: 'Error de Contraseña',
        message: 'Las contraseñas no coinciden. Por favor, verifícalas.',
        isError: true,
      );
      return;
    }

    if (!_termsAccepted) {
      _showFeedbackDialog(
        title: 'Términos y Condiciones',
        message: 'Debes aceptar los términos y condiciones para poder crear una cuenta.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerPatient(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        cedula: '',
        telefono: _telefonoController.text.trim(),
        city: widget.selectedCity,
      );

      if (mounted && user != null) {
        _showFeedbackDialog(
          title: '¡Registro Exitoso!',
          message: 'Tu cuenta ha sido creada. Ahora puedes iniciar sesión.',
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)..pop()..pop();
              },
              child: const Text('Ir a Iniciar Sesión'),
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        _showFeedbackDialog(
          title: 'Error de Registro',
          message: e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- NOVEDAD: Lógica para registro con redes sociales ---
  Future<void> _socialRegister(Future<User?> Function() loginMethod) async {
    setState(() => _isLoading = true);
    try {
      await loginMethod();

      if (mounted) {
        // Solo regreso una pantalla para que AuthGate maneje el flujo
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showFeedbackDialog(
          title: 'Error de Autenticación',
          message: e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _showTermsDialog() {
    const String termsText = '''CONTRATO DE PROMOCION, COORDINACION Y PRESTACION DE SERVICIOS DE CIRUGIA MÉDICO ESTÉTICO, BARIATRICO Y/O ODONTOLÓGICO
En el país Ecuador, ciudad de Guayaquil, de manera electrónica, el día de hoy, mediante aceptación electrónica del El Paciente, comparecen e intervienen las siguientes personas naturales y jurídicas: 1) CIRUGIASDELUJOECUADOR S.A.S., con número de R.U.C. 0993391365001, por intermedio de su representante legal, judicial y extrajudicial el señor Ángel Joel Figueroa Rivera, accionista fundador y Gerente General, con domicilio en esta ciudad de Guayaquil y domicilio electrónico cirugiasdelujoecuador@gmail.com, a quien en adelante se le denominará El Promotor; 2) El profesional seleccionado por el paciente en el APP Cirugías de Lujo Ecuador, quien se encuentra registrado en la base de datos de la compañía CIRUGUASDELUJOECUADOR S.A.S. mediante contrato de colaboración entre promotor y médico, a quien   en   adelante   se   le   denominará   El   Médico, El   Médico  Tratante y/o El Prestador; y, 3) EL PACIENTE, quien se registró de manera oportuna y electrónica en el APP Cirugías de Lujo Ecuador, a quien en adelante se le denominará El Paciente y/o El Cliente.
Todos con capacidad civil y legal para celebrar cualquier tipo de acto u contrato. Las partes acuerdan celebrar este contrato de forma libre y voluntaria, sujeto a las siguientes cláusulas:
PRIMERA: Objeto. - El presente contrato tiene por objeto establecer las condiciones bajo las cuales EL PROMOTOR refiere o canaliza a EL PACIENTE, por intermedio del App Cirugías de Lujo Ecuador de propiedad de la compañía CIRUGIASDELUJOECUADOR S.A.S., a los servicios médico-estéticos prestados por EL MÉDICO, quien será el único responsable de la evaluación, ejecución, seguimiento y resultado del procedimiento quirúrgico.
EL MEDICO se obliga a realizar a favor de EL PACIENTE, el procedimiento médico-estético seleccionado por el paciente en el app Cirugías de Lujo Ecuador, conforme a las normas técnicas y éticas vigentes, y según el diagnóstico médico previamente realizado por El Médico.
EL PROMOTOR, actúa exclusivamente como coordinador logístico e informativo. Toda valoración médica, procedimiento quirúrgico y seguimiento es responsabilidad exclusiva del cirujano tratante.”
SEGUNDA: Funciones Del Promotor. - EL PROMOTOR actúa como intermediario informativo, comercial y logístico, siendo sus funciones principales: 1. Promocionar y divulgar los servicios médico-estéticos de EL MÉDICO por todos los medios en línea posibles. 2. Brindar información general (no médica) sobre los procedimientos ofrecidos. 3. Coordinar citas, asesorías iniciales y atención al cliente. 4. Canalizar la comunicación entre EL PACIENTE y EL MÉDICO. 5. EL PROMOTOR no realiza diagnósticos, valoraciones médicas ni emite conceptos clínicos. Cualquier decisión médica será tomada exclusivamente por EL MÉDICO.
TERCERA: Procedimiento Médico. - EL MÉDICO se compromete a realizar a favor de EL PACIENTE el procedimiento médico-estético seleccionado por el paciente en el app Cirugías de Lujo Ecuador, según evaluación médica previa y firma de consentimiento informado.
CUARTA: El Médico declara que tiene póliza de seguro destinada a cubrir los riesgos derivados del ejercicio profesional médico mediante un contrato de seguro de responsabilidad civil profesional médica
La Aseguradora contratada por el médico, se obliga a cubrir, dentro de los límites establecidos, la responsabilidad civil derivada de daños personales, materiales y/o morales causados a terceros como consecuencia directa de actos profesionales realizados por El médico en el ejercicio de su actividad médica del presente contrato, en el cual incluye cobertura en: 1) Indemnizaciones por daños personales, materiales o morales a pacientes. 2) Gastos judiciales y honorarios legales en caso de litigio. 3) Errores, omisiones o negligencias cometidas en el ejercicio de la actividad médica.
Deslindando y eximiendo de toda responsabilidad Civil, Penal y Constitucional a El promotor por la actuación de El Médico.
QUINTA: Costo y forma de Pago. - El costo total del procedimiento será el ya seleccionado por EL PACIENTE en el app Cirugía de Lujo Ecuador, que se encuentra registrado en la base de datos de EL PROMOTOR. El pago podrá realizarse de la siguiente manera: Por intermedio de EL PROMOTOR, por su app quien dirigirá el pago directamente a la cuenta bancaria de EL MEDICO, quien deberá entregar al PACIENTE comprobante de recibo y EL MEDICO transferirá la comisión de 150 dólares por cada agendamiento de cirugía realizado a la cuenta bancaria de EL PROMOTOR descrita en el contrato de colaboración entre promotor y médico, en el término máximo de 5 días. Y el médico dará la confirmación de agendamiento para el cliente.
Formas de pago: 1) Pago al contado; y, 2) Financiamiento: EL CLIENTE podrá pagar en cuotas mensuales a través de la entidad financiera a nombre del Médico.
La forma de pago del presente contrato se encuentra designada y aceptada POR EL CLIENTE mediante selección de EL CLIENTE en el app Cirugías de Lujo Ecuador con registro en la base de datos de EL PROMOTOR. Cualquier mora en el pago será asumida por EL CLIENTE, quien acepta que una vez cancelado el total del costo de la presente cláusula será agendado para la valoración con el médico.
SEXTA: Consentimiento Informado. - EL PACIENTE declara que exigirá en la valoración física con EL MÉDICO, mediante el agendamiento realizado por EL PROMOTOR, firmar el contrato de consentimiento informado, recibiendo explicación detallada sobre: 1) El procedimiento a realizar, 2) Los riesgos inherentes y posibles complicaciones, 3) Resultados esperados y reales, 4) Alternativas disponibles. Dicho consentimiento será otorgado por EL MÉDICO mediante escrito en documento separado al presente contrato.
EL PACIENTE acepta que el presente aplicativo es de promoción, coordinación y captación de clientes para que EL MÉDICO preste sus servicios como médicos especialistas tratantes de acuerdo a su especialidad.
SEPTIMA: Responsabilidades. - EL MÉDICO es el único responsable del acto médico, de la ejecución del procedimiento y del seguimiento postoperatorio. EL PROMOTOR no asume responsabilidad médica o legal sobre los resultados clínicos. EL PACIENTE es responsable de cumplir con las indicaciones médicas, exámenes preoperatorios y seguimiento postoperatorio.
“En ningún caso se configurará responsabilidad solidaria entre EL MÉDICO y EL PROMOTOR. Cada uno responderá únicamente por los actos propios derivados de sus funciones específicas,
OCTAVA: Comisiones y Transparencia. - EL PACIENTE reconoce que EL PROMOTOR puede recibir una comisión económica por parte del MÉDICO por su labor de promoción y coordinación. Dicha comisión no incrementa el valor final del procedimiento pactado con EL PACIENTE.
NOVENA: Cancelación y Reembolso. – Si EL PACIENTE cancela el procedimiento se reembolsará el valor pagado menos 150 dólares, por gastos administrativos, si no comparece al agendamiento para la valoración médica puede implicar la pérdida parcial del monto pagado y se reembolsará el valor pagado menos 80 dólares, por gastos administrativos y/o el cliente podrá reagendar su cita con el médico por medio de llamada telefónica al promotor a los números de EL PROMOTOR estipulados en el app o cualquier medio digital; y, por causa médica certificada mediante el informe de valoración de EL MÉDICO, se reembolsará el valor pagado menos 150 dólares, por gastos administrativos, considerando las partes como una cláusula no abusiva.
DÉCIMA: Intervenciones Complementarias. - Las siguientes intervenciones o servicios adicionales podrán ser requeridos o sugeridos por razones médicas o estéticas, en la valoración con el médico: como por ejemplo Revisión o retoque postoperatorio, sesiones de drenaje linfático, seguimiento con dermatólogo, etc, estos servicios no están incluidos en el costo total del procedimiento. En caso de no estar incluidos, serán cotizados y autorizados previamente por EL CLIENTE en conjunto con el médico.
DÉCIMA PRIMERA: Responsabilidad y Resultados. - EL MEDICO se compromete a actuar con la diligencia debida y en cumplimiento de la lex artis médica. No obstante, se deja constancia de que los resultados estéticos son subjetivos y variables, dependiendo de factores biológicos del paciente, adicional a las obligaciones del paciente estipulados en la cláusula segunda del presente contrato, por lo que no se garantiza un resultado exacto.
DÉCIMA SEGUNDA: Obligaciones del paciente después de la intervención quirúrgica. – el incumplimiento de cualquier numeral de la presente cláusula al no ser informada cada quince días es considerada como no realizada y se entenderá el incumplimiento de parte de EL PACIENTE
1. Cumplir con los controles postoperatorios: Asistir puntualmente a todas las citas de seguimiento programadas por el médico tratante. Informar al médico cada quince días vía whatsapp, sms y/o correo electrónico, si presenta dificultades para asistir o si nota síntomas inusuales.
2. Seguir estrictamente las indicaciones médicas: Tomar los medicamentos recetados en la dosis y horarios indicados. No auto medicarse ni suspender tratamientos sin autorización médica de EL MÉDICO, aplicar curaciones, cremas o vendajes según las instrucciones dadas, todo debe ser documentado y notificado por vía whatsapp, sms y/o correo electrónico, para ser sustentado como prueba fehaciente, el no envío se considerará como no realizado. y/o incumplimiento de las obligaciones
3. Mantener reposo y evitar esfuerzos físicos: Respetar los tiempos mínimos de reposo absoluto y relativo. Evitar levantar peso, hacer ejercicio, conducir o actividades que comprometan la zona intervenida.
4. Usar prendas o fajas postoperatorias: Usar correctamente las prendas de compresión (si el procedimiento lo requiere), en el tiempo y forma recomendada. No retirar sin indicación médica, ya que podrían afectar el resultado estético y funcional.
5. Vigilar signos de alarma: Estar atento(a) a signos de infección, sangrado, fiebre, dolor incontrolable, dificultad respiratoria u otros síntomas. Notificar inmediatamente al médico ante cualquier signo de complicación.
6. Cumplir con los cuidados higiénicos: Mantener limpia y seca la zona intervenida según las indicaciones. No exponer la herida a humedad excesiva (piscinas, baños prolongados) hasta que el médico lo autorice.
7. Evitar consumo de sustancias prohibidas: No consumir alcohol, tabaco, ni otras sustancias que interfieran con la cicatrización o los medicamentos. Informar si se consumen suplementos o productos naturales que puedan interferir.
8. Informar cambios o molestias no previstos: Comunicar cualquier incomodidad, deformidad, bulto, asimetría, o sensación extraña, incluso si parece menor. No acudir a terceros sin autorización médica como por ejemplo masajes, esteticistas, etc.
9. Evitar exposición solar directa: No exponer la zona operada al sol sin protección, especialmente en los primeros 30-60 días. Usar bloqueador solar si el procedimiento lo requiere.
10. No exigir resultados inmediatos ni definitivos: Comprender que la inflamación, hematomas o irregularidades son normales en las primeras semanas. Seguir el proceso completo de recuperación antes de evaluar el resultado final (en algunos casos hasta 6 meses o más).
DÉCIMA TERCERA: Deslinde de responsabilidad del promotor. - EL PACIENTE reconoce y acepta que EL PROMOTOR actúa únicamente como intermediario informativo y comercial, cuya función se limita a promocionar, coordinar y facilitar el contacto entre el paciente y el profesional médico tratante y/o el médico.
EL PROMOTOR no realiza evaluaciones médicas, diagnósticos, indicaciones clínicas ni participa en la ejecución del procedimiento quirúrgico. Por tanto, cualquier responsabilidad derivada del acto médico, incluyendo diagnósticos, intervenciones quirúrgicas, tratamientos postoperatorios, resultados o complicaciones médicas, corresponde única y exclusivamente al profesional médico tratante y su equipo de salud, conforme a la lex artis médica y la legislación ecuatoriana vigente.
EL PACIENTE ha sido informado y ha tenido la oportunidad de realizar una evaluación médica independiente antes de decidir someterse al procedimiento.
DÉCIMA CUARTA: Confidencialidad y protección de datos. - Las partes acuerdan proteger la confidencialidad de la información personal, médica y financiera, conforme a las leyes de protección de datos personales vigentes.
DÉCIMA QUINTA: No captación de clientela y protección comercial. - El MÉDICO reconoce que EL PROMOTOR, a través de sus propios recursos, plataformas y medios de promoción, ha desarrollado una red de captación de clientes/pacientes, lo cual representa una inversión de tiempo, dinero y posicionamiento estratégico. En virtud de lo anterior, EL MÉDICO se compromete a no contactar, captar, recibir, atender o prestar servicios médicos de manera directa o indirecta a ningún paciente referido por EL PROMOTOR sin la participación o autorización expresa, previa y por escrito de este último. Esta prohibición aplicará durante la vigencia del presente contrato y se extenderá por un periodo de doce meses después de su terminación, por cualquier causa. 
Para efectos de esta cláusula, se entenderá como “paciente referido” a toda persona que haya sido canalizada por EL PROMOTOR a través de: Entrevistas, agendas, redes sociales, formularios, referidos por WhatsApp, correos electrónicos, consultas o citas programadas por el promotor o que haya tenido un primer contacto con EL MÉDICO como resultado de la actividad de promoción del PROMOTOR. En caso de que un paciente referido continúe tratamiento con EL MÉDICO sin intervención del PROMOTOR, EL MÉDICO deberá informar de inmediato dicha situación y reconocer la comisión correspondiente, si la relación se dio como resultado de la labor del promotor.
El incumplimiento de esta cláusula dará lugar a una penalidad económica equivalente al 100% del valor total de los servicios prestados a dicho paciente, sin perjuicio de otras acciones legales a que haya lugar.
DÉCIMA SEXTA: Respaldo probatorio. – EL MEDICO y EL PROMOTOR acuerdan que se podrán usar como medios de prueba las capturas de pantalla, correos electrónicos, chats, agendas digitales, sistemas de reservas, mensajes de redes sociales u otros registros electrónicos que demuestren la procedencia del paciente desde el canal de EL PROMOTOR.
DÉCIMA SEPTIMA: Vigencia y jurisdicción. - Este contrato se encuentra en vigencia entre EL MÉDICO y EL PROMOTOR por contrato anteriormente suscrito entre promotor y médico; y, entra en vigencia de EL PACIENTE a partir de la firma y/o aceptación electrónica dentro del app y se mantendrá vigente hasta la culminación del tratamiento y sus controles postoperatorios. Cualquier disputa o controversia será resuelta ante las Unidades Judiciales Civiles de la Ciudad de Guayaquil, conforme a las leyes del Ecuador.
DÉCIMA OCTAVA: Bonificación por volumen de referidos. - EL MÉDICO reconoce y valora el esfuerzo comercial y de captación realizado por EL PROMOTOR. En virtud de ello, se compromete a otorgar a EL PROMOTOR un beneficio equivalente a una cirugía o procedimiento médico-estético de cortesía por cada cinco pacientes referidos que hayan sido efectivamente intervenidos y cuyo pago haya sido completado. Este beneficio podrá ser utilizado por el propio PROMOTOR o por un tercero designado por él, siempre que se trate de un procedimiento dentro del portafolio habitual de EL MÉDICO y cuya complejidad y costo no excedan los estándares económicos promedio de los procedimientos contratados por los pacientes aportados.
El procedimiento bonificado: No generará costos médicos para EL PROMOTOR, salvo insumos especiales o exámenes prequirúrgicos si son requeridos. Deberá agendarse en fecha coordinada entre las partes, sin interferir con la agenda habitual del consultorio. El cómputo de los pacientes se reiniciará después de cada grupo de cinco (5) pacientes operados, y los beneficios obtenidos son acumulables y transferibles entre ciclos diferentes sin consentimiento escrito. EL PROMOTOR podrá solicitar por escrito el uso de dicho beneficio una vez cumplido el quinto caso, y EL MÉDICO deberá honrar el compromiso dentro de los 30 días siguientes, salvo causas médicas, logísticas o de fuerza mayor debidamente comprobadas.
DÉCIMA NOVENA: Tarifas preferenciales para pacientes del promotor. - EL MÉDICO se compromete a ofrecer tarifas preferenciales con descuento de un 30% para los pacientes derivados directamente por EL PROMOTOR, siempre respetando un precio mínimo garantizado por procedimiento, según lo establecido en el contrato entre EL MÉDICO y EL PROMOTOR. Estas tarifas no se aplicarán a pacientes que no hayan sido canalizados mediante el app Cirugías de Lujo Ecuador ni afectarán el valor comercial comunicado al paciente.
VIGÉSIMA: Validez de aceptación electrónica. - Las partes reconocen que la aceptación electrónica del presente contrato por parte de EL PACIENTE, mediante el app Cirugías de Lujo Ecuador, así como las comunicaciones digitales entre las partes, constituyen prueba legal válida conforme a la Ley de Comercio Electrónico, Firmas Electrónicas y Mensajes de Datos vigente en la República del Ecuador.
VIGÉSIMA PRIMERA: Resolución y sanción.
El incumplimiento grave de cualquiera de las obligaciones establecidas en el presente contrato, especialmente las relacionadas con el pago, la confidencialidad, o la captación de clientela, faculta a EL PROMOTOR a resolver unilateralmente el contrato sin necesidad de declaración judicial, bastando notificación electrónica a las direcciones registradas.
En tal caso, EL PROMOTOR podrá retener o descontar valores por daños, perjuicios y costos administrativos derivados del incumplimiento.
Las partes intervinientes aceptan el presente contrato de manera electrónica y fijan su domicilio para citaciones y notificaciones los correos electrónicos estipulados en la base de datos del app de EL PROMOTOR.''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF81D4FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Términos y Condiciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              termsText,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 12, color: primaryTextColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red.shade400 : primaryBlue,
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: actions ?? [ ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Aceptar')) ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crear Cuenta', style: TextStyle(color: primaryTextColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: Stack(
        children: [
          // --- CAMBIO: Color de fondo actualizado ---
          Container(color: const Color(0xFF00A9FF)),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                          Image.asset(
                            'assets/images/logo2.png',
                            height: 120,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.medical_services_outlined, size: 100, color: primaryBlue),
                          ),
                          const SizedBox(height: 16),
                          // --- CAMBIO: Color de texto del título ---
                          const Text('Únete a la Experiencia', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          // --- CAMBIO: Color de texto del subtítulo ---
                          Text('Completa tus datos para empezar en ${widget.selectedCity}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                          const SizedBox(height: 24),
                          _buildTextField(controller: _nombreController, label: 'Nombres', inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))]),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _apellidoController, label: 'Apellidos', inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))]),
                          const SizedBox(height: 16),
                          //  AJUSTE 1: Aplicar limitación visual de 10 dígitos al campo Teléfono
                          _buildTextField(
                            controller: _telefonoController,
                            label: 'Teléfono',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10), // Limita visualmente a 10
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _emailController, label: 'Correo Electrónico', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _passwordController, label: 'Contraseña', isPassword: true, showPassword: _showPassword, onToggleVisibility: () => setState(() => _showPassword = !_showPassword)),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _confirmPasswordController, label: 'Confirmar Contraseña', isPassword: true, showPassword: _showConfirmPassword, onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword)),
                          const SizedBox(height: 24),
                          CheckboxListTile(
                            value: _termsAccepted,
                            onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                            title: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.white),
                                children: [
                                  const TextSpan(text: 'He leído y acepto los '),
                                  TextSpan(
                                    text: 'Términos y Condiciones',
                                    style: const TextStyle(color: primaryBlue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                                  ),
                                ],
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _termsAccepted ? primaryBlue : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('CREAR CUENTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 24),

                          // --- NOVEDAD: Divisor y botones sociales ---
                          _buildDivider(),
                          const SizedBox(height: 24),
                          _buildSocialButtons(),
                          const SizedBox(height: 24),

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
                        Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.7)),
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
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onToggleVisibility,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !showPassword,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: primaryTextColor),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: onToggleVisibility)
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: const BorderSide(color: primaryBlue, width: 2.0)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio.';


        if (label == 'Teléfono' && value.trim().length != 10) {
          return 'El número de teléfono debe ser de exactamente 10 dígitos.';
        }

        if (label == 'Correo Electrónico' && !value.contains('@')) return 'Por favor, ingresa un correo válido.';
        if (label.contains('Contraseña') && value.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
        return null;
      },
    );
  }

  // --- NOVEDAD: Widget para el divisor ---
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Colors.white70)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text('o registrarse con', style: TextStyle(color: Colors.white.withOpacity(0.9))),
        ),
        const Expanded(child: Divider(thickness: 1, color: Colors.white70)),
      ],
    );
  }

  // --- NOVEDAD: Widget para los botones sociales ---
  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(icon: FontAwesomeIcons.google, color: Colors.red, onPressed: _isLoading ? (){} : () => _socialRegister(_authService.signInWithGoogle)),
        // Botón de Facebook comentado temporalmente a petición del usuario
        /*
        const SizedBox(width: 24),
        _buildSocialButton(icon: FontAwesomeIcons.facebook, color: Colors.blue.shade800, onPressed: _isLoading ? (){} : () => _socialRegister(_authService.signInWithFacebook)),
        */
      ],
    );
  }

  // --- NOVEDAD: Widget para un botón social individual ---
  Widget _buildSocialButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1), color: Colors.white),
        child: FaIcon(icon, color: color, size: 24),
      ),
    );
  }
}