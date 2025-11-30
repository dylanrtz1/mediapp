import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  // Paleta de colores a nivel de clase para poder usarlos en los helpers
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _primaryTextColor = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: Colors.white,
        foregroundColor: _primaryTextColor,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                  'CONTRATO DE PROMOCIÓN, COORDINACIÓN Y PRESTACIÓN DE SERVICIOS DE CIRUGÍA MÉDICO-ESTÉTICO, BARIÁTRICO Y/O ODONTOLÓGICO'),
              _buildParagraph(
                '''En el país Ecuador, ciudad de Guayaquil, de manera electrónica, el día de hoy, mediante aceptación electrónica de El Paciente, comparecen e intervienen las siguientes personas naturales y jurídicas: 1) CIRUGIASDELUJOECUADOR S.A.S., con número de R.U.C. 0993391365001, por intermedio de su representante legal, judicial y extrajudicial el señor Ángel Joel Figueroa Rivera, accionista fundador y Gerente General, con domicilio en esta ciudad de Guayaquil y domicilio electrónico cirugiasdelujoecuador@gmail.com, a quien en adelante se le denominará El Promotor; 2) El profesional seleccionado por el paciente en el APP Cirugías de Lujo Ecuador, quien se encuentra registrado en la base de datos de la compañía CIRUGIASDELUJOECUADOR S.A.S. mediante contrato de colaboración entre promotor y médico, a quien en adelante se le denominará El Médico, El Médico Tratante y/o El Prestador; y, 3) EL PACIENTE, quien se registró de manera oportuna y electrónica en el APP Cirugías de Lujo Ecuador, a quien en adelante se le denominará El Paciente y/o El Cliente.

Todos con capacidad civil y legal para celebrar cualquier tipo de acto o contrato. Las partes acuerdan celebrar este contrato de forma libre y voluntaria, sujeto a las siguientes cláusulas:''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('PRIMERA: Objeto'),
              _buildParagraph(
                '''El presente contrato tiene por objeto establecer las condiciones bajo las cuales EL PROMOTOR refiere o canaliza a EL PACIENTE, por intermedio del App Cirugías de Lujo Ecuador de propiedad de la compañía CIRUGIASDELUJOECUADOR S.A.S., a los servicios médico-estéticos prestados por EL MÉDICO, quien será el único responsable de la evaluación, ejecución, seguimiento y resultado del procedimiento quirúrgico.

EL MÉDICO se obliga a realizar a favor de EL PACIENTE el procedimiento médico-estético seleccionado por el paciente en el app Cirugías de Lujo Ecuador, conforme a las normas técnicas y éticas vigentes, y según el diagnóstico médico previamente realizado por EL MÉDICO.

EL PROMOTOR actúa exclusivamente como coordinador logístico e informativo. Toda valoración médica, procedimiento quirúrgico y seguimiento es responsabilidad exclusiva del cirujano tratante.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('SEGUNDA: Funciones del Promotor'),
              _buildParagraph(
                '''EL PROMOTOR actúa como intermediario informativo, comercial y logístico, siendo sus funciones principales: 
1) Promocionar y divulgar los servicios médico-estéticos de EL MÉDICO por todos los medios en línea posibles. 
2) Brindar información general (no médica) sobre los procedimientos ofrecidos. 
3) Coordinar citas, asesorías iniciales y atención al cliente. 
4) Canalizar la comunicación entre EL PACIENTE y EL MÉDICO. 
5) EL PROMOTOR no realiza diagnósticos, valoraciones médicas ni emite conceptos clínicos. Cualquier decisión médica será tomada exclusivamente por EL MÉDICO.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('TERCERA: Procedimiento Médico'),
              _buildParagraph(
                '''EL MÉDICO se compromete a realizar a favor de EL PACIENTE el procedimiento médico-estético seleccionado por el paciente en el app Cirugías de Lujo Ecuador, según evaluación médica previa y firma de consentimiento informado.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('CUARTA: Póliza de Seguro'),
              _buildParagraph(
                '''EL MÉDICO declara que tiene póliza de seguro destinada a cubrir los riesgos derivados del ejercicio profesional médico mediante un contrato de seguro de responsabilidad civil profesional médica. La aseguradora contratada por el médico se obliga a cubrir, dentro de los límites establecidos, la responsabilidad civil derivada de daños personales, materiales y/o morales causados a terceros como consecuencia directa de actos profesionales realizados por EL MÉDICO en el ejercicio de su actividad médica del presente contrato, en el cual incluye cobertura en: 
1) Indemnizaciones por daños personales, materiales o morales a pacientes. 
2) Gastos judiciales y honorarios legales en caso de litigio. 
3) Errores, omisiones o negligencias cometidas en el ejercicio de la actividad médica.

Se deslinda y exonera de toda responsabilidad civil, penal y constitucional a EL PROMOTOR por la actuación de EL MÉDICO.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('QUINTA: Costo y Forma de Pago'),
              _buildParagraph(
                '''El costo total del procedimiento será el ya seleccionado por EL PACIENTE en el app Cirugías de Lujo Ecuador, que se encuentra registrado en la base de datos de EL PROMOTOR. 

El pago podrá realizarse de la siguiente manera: por intermedio de EL PROMOTOR, por su app, quien dirigirá el pago directamente a la cuenta bancaria de EL MÉDICO, quien deberá entregar a EL PACIENTE comprobante de recibo; y EL MÉDICO transferirá la comisión de USD 150 por cada agendamiento de cirugía realizado a la cuenta bancaria de EL PROMOTOR descrita en el contrato de colaboración entre promotor y médico, en el término máximo de cinco (5) días. EL MÉDICO dará la confirmación de agendamiento para el cliente.

Formas de pago: 
1) Pago al contado; y, 
2) Financiamiento: EL CLIENTE podrá pagar en cuotas mensuales a través de la entidad financiera a nombre del médico.

La forma de pago del presente contrato se encuentra designada y aceptada por EL CLIENTE mediante selección en el app Cirugías de Lujo Ecuador con registro en la base de datos de EL PROMOTOR. Cualquier mora en el pago será asumida por EL CLIENTE, quien acepta que una vez cancelado el total del costo de la presente cláusula será agendado para la valoración con el médico.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('SEXTA: Consentimiento Informado'),
              _buildParagraph(
                '''EL PACIENTE declara que exigirá en la valoración física con EL MÉDICO, mediante el agendamiento realizado por EL PROMOTOR, firmar el contrato de consentimiento informado, recibiendo explicación detallada sobre: 
1) El procedimiento a realizar, 
2) Los riesgos inherentes y posibles complicaciones, 
3) Resultados esperados y reales, 
4) Alternativas disponibles. 

Dicho consentimiento será otorgado por EL MÉDICO mediante escrito en documento separado al presente contrato. EL PACIENTE acepta que el presente aplicativo es de promoción, coordinación y captación de clientes para que EL MÉDICO preste sus servicios como médico especialista tratante de acuerdo con su especialidad.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('SÉPTIMA: Responsabilidades'),
              _buildParagraph(
                '''EL MÉDICO es el único responsable del acto médico, de la ejecución del procedimiento y del seguimiento postoperatorio. EL PROMOTOR no asume responsabilidad médica o legal sobre los resultados clínicos. EL PACIENTE es responsable de cumplir con las indicaciones médicas, exámenes preoperatorios y seguimiento postoperatorio.

En ningún caso se configurará responsabilidad solidaria entre EL MÉDICO y EL PROMOTOR. Cada uno responderá únicamente por los actos propios derivados de sus funciones específicas.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('OCTAVA: Comisiones y Transparencia'),
              _buildParagraph(
                '''EL PACIENTE reconoce que EL PROMOTOR puede recibir una comisión económica por parte de EL MÉDICO por su labor de promoción y coordinación. Dicha comisión no incrementa el valor final del procedimiento pactado con EL PACIENTE.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('NOVENA: Cancelación y Reembolso'),
              _buildParagraph(
                '''Si EL PACIENTE cancela el procedimiento, se reembolsará el valor pagado menos USD 150 por gastos administrativos. Si no comparece al agendamiento para la valoración médica, puede implicar la pérdida parcial del monto pagado, reembolsándose el valor pagado menos USD 80 por gastos administrativos; y/o EL CLIENTE podrá reagendar su cita con el médico por medio de llamada telefónica a EL PROMOTOR a los números estipulados en el app o por cualquier medio digital. Por causa médica certificada mediante el informe de valoración de EL MÉDICO, se reembolsará el valor pagado menos USD 150 por gastos administrativos, considerando las partes esta estipulación como una cláusula no abusiva.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('DÉCIMA: Intervenciones Complementarias'),
              _buildParagraph(
                '''Las siguientes intervenciones o servicios adicionales podrán ser requeridos o sugeridos por razones médicas o estéticas, en la valoración con el médico: por ejemplo, revisión o retoque postoperatorio, sesiones de drenaje linfático, seguimiento con dermatólogo, etc. Estos servicios no están incluidos en el costo total del procedimiento. En caso de no estar incluidos, serán cotizados y autorizados previamente por EL CLIENTE en conjunto con EL MÉDICO.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('DÉCIMA PRIMERA: Responsabilidad y Resultados'),
              _buildParagraph(
                '''EL MÉDICO se compromete a actuar con la diligencia debida y en cumplimiento de la lex artis médica. No obstante, se deja constancia de que los resultados estéticos son subjetivos y variables, dependiendo de factores biológicos del paciente, además de las obligaciones del paciente estipuladas en la cláusula segunda del presente contrato; por lo tanto, no se garantiza un resultado exacto.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle(
                  'DÉCIMA SEGUNDA: Obligaciones del Paciente después de la Intervención Quirúrgica'),
              _buildParagraph(
                '''El incumplimiento de cualquier numeral de la presente cláusula, al no ser informado cada quince (15) días, es considerado como no realizado y se entenderá el incumplimiento de parte de EL PACIENTE:

1) Cumplir con los controles postoperatorios: asistir puntualmente a todas las citas de seguimiento programadas por el médico tratante. Informar al médico cada quince días vía WhatsApp, SMS y/o correo electrónico si presenta dificultades para asistir o si nota síntomas inusuales.

2) Seguir estrictamente las indicaciones médicas: tomar los medicamentos recetados en la dosis y horarios indicados. No automedicarse ni suspender tratamientos sin autorización de EL MÉDICO. Aplicar curaciones, cremas o vendajes según las instrucciones dadas. Todo debe ser documentado y notificado por vía WhatsApp, SMS y/o correo electrónico, para ser sustentado como prueba fehaciente; el no envío se considerará como no realizado y/o incumplimiento de las obligaciones.

3) Mantener reposo y evitar esfuerzos físicos: respetar los tiempos mínimos de reposo absoluto y relativo. Evitar levantar peso, hacer ejercicio, conducir o actividades que comprometan la zona intervenida.

4) Usar prendas o fajas postoperatorias: usar correctamente las prendas de compresión (si el procedimiento lo requiere), en el tiempo y forma recomendada. No retirar sin indicación médica, ya que podrían afectar el resultado estético y funcional.

5) Vigilar signos de alarma: estar atento(a) a signos de infección, sangrado, fiebre, dolor incontrolable, dificultad respiratoria u otros síntomas. Notificar inmediatamente al médico ante cualquier signo de complicación.

6) Cumplir con los cuidados higiénicos: mantener limpia y seca la zona intervenida según las indicaciones. No exponer la herida a humedad excesiva (piscinas, baños prolongados) hasta que el médico lo autorice.

7) Evitar consumo de sustancias prohibidas: no consumir alcohol, tabaco, ni otras sustancias que interfieran con la cicatrización o los medicamentos. Informar si se consumen suplementos o productos naturales que puedan interferir.

8) Informar cambios o molestias no previstas: comunicar cualquier incomodidad, deformidad, bulto, asimetría o sensación extraña, incluso si parece menor. No acudir a terceros sin autorización médica (por ejemplo, masajes, esteticistas, etc.).

9) Evitar exposición solar directa: no exponer la zona operada al sol sin protección, especialmente en los primeros 30 a 60 días. Usar bloqueador solar si el procedimiento lo requiere.

10) No exigir resultados inmediatos ni definitivos: comprender que la inflamación, hematomas o irregularidades son normales en las primeras semanas. Seguir el proceso completo de recuperación antes de evaluar el resultado final (en algunos casos hasta seis meses o más).''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('DÉCIMA TERCERA: Deslinde de Responsabilidad del Promotor'),
              _buildParagraph(
                '''EL PACIENTE reconoce y acepta que EL PROMOTOR actúa únicamente como intermediario informativo y comercial, cuya función se limita a promocionar, coordinar y facilitar el contacto entre el paciente y el profesional médico tratante.

EL PROMOTOR no realiza evaluaciones médicas, diagnósticos, indicaciones clínicas ni participa en la ejecución del procedimiento quirúrgico. Por tanto, cualquier responsabilidad derivada del acto médico, incluyendo diagnósticos, intervenciones quirúrgicas, tratamientos postoperatorios, resultados o complicaciones médicas, corresponde única y exclusivamente al profesional médico tratante y su equipo de salud, conforme a la lex artis médica y la legislación ecuatoriana vigente.

EL PACIENTE ha sido informado y ha tenido la oportunidad de realizar una evaluación médica independiente antes de decidir someterse al procedimiento.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('DÉCIMA CUARTA: Confidencialidad y Protección de Datos'),
              _buildParagraph(
                '''Las partes acuerdan proteger la confidencialidad de la información personal, médica y financiera, conforme a las leyes de protección de datos personales vigentes.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle(
                  'DÉCIMA QUINTA: No Captación de Clientela y Protección Comercial'),
              _buildParagraph(
                '''EL MÉDICO reconoce que EL PROMOTOR, a través de sus propios recursos, plataformas y medios de promoción, ha desarrollado una red de captación de clientes/pacientes, lo cual representa una inversión de tiempo, dinero y posicionamiento estratégico. En virtud de lo anterior, EL MÉDICO se compromete a no contactar, captar, recibir, atender o prestar servicios médicos de manera directa o indirecta a ningún paciente referido por EL PROMOTOR sin la participación o autorización expresa, previa y por escrito de este último. Esta prohibición aplicará durante la vigencia del presente contrato y se extenderá por un periodo de doce (12) meses después de su terminación, por cualquier causa. 

Para efectos de esta cláusula, se entenderá como “paciente referido” a toda persona que haya sido canalizada por EL PROMOTOR a través de: entrevistas, agendas, redes sociales, formularios, referidos por WhatsApp, correos electrónicos, consultas o citas programadas por el promotor, o que haya tenido un primer contacto con EL MÉDICO como resultado de la actividad de promoción de EL PROMOTOR. En caso de que un paciente referido continúe tratamiento con EL MÉDICO sin intervención de EL PROMOTOR, EL MÉDICO deberá informar de inmediato dicha situación y reconocer la comisión correspondiente, si la relación se dio como resultado de la labor del promotor.

El incumplimiento de esta cláusula dará lugar a una penalidad económica equivalente al 100% del valor total de los servicios prestados a dicho paciente, sin perjuicio de otras acciones legales a que haya lugar.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('DÉCIMA SEXTA: Respaldo Probatorio'),
              _buildParagraph(
                '''EL MÉDICO y EL PROMOTOR acuerdan que se podrán usar como medios de prueba las capturas de pantalla, correos electrónicos, chats, agendas digitales, sistemas de reservas, mensajes de redes sociales u otros registros electrónicos que demuestren la procedencia del paciente desde el canal de EL PROMOTOR.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('DÉCIMA SÉPTIMA: Vigencia y Jurisdicción'),
              _buildParagraph(
                '''Este contrato se encuentra en vigencia entre EL MÉDICO y EL PROMOTOR por contrato anteriormente suscrito entre promotor y médico; y entra en vigencia con EL PACIENTE a partir de la firma y/o aceptación electrónica dentro del app y se mantendrá vigente hasta la culminación del tratamiento y sus controles postoperatorios. Cualquier disputa o controversia será resuelta ante las Unidades Judiciales Civiles de la ciudad de Guayaquil, conforme a las leyes del Ecuador.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle(
                  'DÉCIMA OCTAVA: Bonificación por Volumen de Referidos'),
              _buildParagraph(
                '''EL MÉDICO reconoce y valora el esfuerzo comercial y de captación realizado por EL PROMOTOR. En virtud de ello, se compromete a otorgar a EL PROMOTOR un beneficio equivalente a una cirugía o procedimiento médico-estético de cortesía por cada cinco (5) pacientes referidos que hayan sido efectivamente intervenidos y cuyo pago haya sido completado. Este beneficio podrá ser utilizado por el propio PROMOTOR o por un tercero designado por él, siempre que se trate de un procedimiento dentro del portafolio habitual de EL MÉDICO y cuya complejidad y costo no excedan los estándares económicos promedio de los procedimientos contratados por los pacientes aportados.

El procedimiento bonificado: no generará costos médicos para EL PROMOTOR, salvo insumos especiales o exámenes prequirúrgicos si son requeridos; deberá agendarse en fecha coordinada entre las partes, sin interferir con la agenda habitual del consultorio. El cómputo de los pacientes se reiniciará después de cada grupo de cinco (5) pacientes operados, y los beneficios obtenidos son acumulables y transferibles entre ciclos diferentes sin consentimiento escrito. EL PROMOTOR podrá solicitar por escrito el uso de dicho beneficio una vez cumplido el quinto caso, y EL MÉDICO deberá honrar el compromiso dentro de los treinta (30) días siguientes, salvo causas médicas, logísticas o de fuerza mayor debidamente comprobadas.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle(
                  'DÉCIMA NOVENA: Tarifas Preferenciales para Pacientes del Promotor'),
              _buildParagraph(
                '''EL MÉDICO se compromete a ofrecer tarifas preferenciales con descuento de un 30% para los pacientes derivados directamente por EL PROMOTOR, siempre respetando un precio mínimo garantizado por procedimiento, según lo establecido en el contrato entre EL MÉDICO y EL PROMOTOR. Estas tarifas no se aplicarán a pacientes que no hayan sido canalizados mediante el app Cirugías de Lujo Ecuador ni afectarán el valor comercial comunicado al paciente.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('VIGÉSIMA: Validez de Aceptación Electrónica'),
              _buildParagraph(
                '''Las partes reconocen que la aceptación electrónica del presente contrato por parte de EL PACIENTE, mediante el app Cirugías de Lujo Ecuador, así como las comunicaciones digitales entre las partes, constituyen prueba legal válida conforme a la Ley de Comercio Electrónico, Firmas Electrónicas y Mensajes de Datos vigente en la República del Ecuador.''',
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('VIGÉSIMA PRIMERA: Resolución y Sanción'),
              _buildParagraph(
                '''El incumplimiento grave de cualquiera de las obligaciones establecidas en el presente contrato, especialmente las relacionadas con el pago, la confidencialidad o la captación de clientela, faculta a EL PROMOTOR a resolver unilateralmente el contrato sin necesidad de declaración judicial, bastando notificación electrónica a las direcciones registradas.

En tal caso, EL PROMOTOR podrá retener o descontar valores por daños, perjuicios y costos administrativos derivados del incumplimiento.

Las partes intervinientes aceptan el presente contrato de manera electrónica y fijan como domicilios para citaciones y notificaciones los correos electrónicos estipulados en la base de datos del app de EL PROMOTOR.''',
              ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('He Leído y Acepto'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para títulos
  static Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _primaryTextColor,
      ),
    );
  }

  // Widget auxiliar para párrafos
  static Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 15,
          color: _primaryTextColor,
          height: 1.5, // Espaciado de línea para mejor lectura
        ),
      ),
    );
  }
}
