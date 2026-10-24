// Lo que el asistente sabe de la app (además de los datos reales de la base de datos).
// Mantén esto al día cuando cambie la app.
export const CONOCIMIENTO_APP = `
ACCESO Y REGISTRO:
- Se puede ingresar con correo y contraseña o con Google (no hay acceso con Apple).
- Para registrarse se elige primero un plan (Gratuito, Mensual o Anual). Con correo, se crea la cuenta y se confirma con un código de 6 dígitos que llega al correo; con Google se continúa directamente.
- "Olvidé mi contraseña": se pide el correo, llega un código de 6 dígitos y con él se crea una contraseña nueva.
- Quien se registró con un plan solo puede ingresar con ese plan mientras su inscripción siga vigente (o pendiente de aprobación). Cuando su tiempo termina, puede elegir otro plan.
- Cuando una cuenta nueva se crea, el equipo de FitZone debe aprobarla. Mientras tanto la app muestra "Cuenta en revisión". Al aprobarla llega una notificación y un correo. Si la rechazan se muestra el motivo y se puede escribir a soporte.

PLANES Y PAGOS:
- El plan Gratuito es una prueba de pocos días y no incluye entrenador personal.
- Los planes Mensual y Anual incluyen entrenador personal.
- Métodos de pago: SOLO Efectivo o Pago digital.
  · Efectivo: se paga de forma presencial y el equipo valida el pago.
  · Pago digital: se paga escaneando el código QR Bre-B (sirve desde cualquier banco o billetera) y luego se sube la foto de la factura o comprobante para que el equipo la valide.
- El pago queda pendiente hasta que el equipo lo aprueba; entonces el plan se activa y llega una notificación.
- Al vencer el plan, la app pide elegir y pagar uno nuevo. Antes de vencer llegan avisos de recordatorio.

CONFIGURACIÓN INICIAL (onboarding): es obligatoria y no se puede saltar. Pide: entrenador (solo planes de pago), información personal (edad, género, peso, estatura, condición física, motivación, estrés y energía), mediciones corporales (circunferencias obligatorias; plicometría opcional), objetivo, nivel de experiencia y hábitos de entrenamiento. Todo se puede modificar después desde Ajustes.

PANTALLAS DE LA APP:
- Inicio: rutina de hoy, progreso semanal, accesos rápidos, campana de notificaciones, asistente y tarjeta "Tu Entrenador" con botón Agendar.
- Estadísticas, Logros y Comunidad.
- Mi Plan: el plan semanal de entrenamiento.
- Historial: los entrenamientos terminados, con ejercicios, duración y calorías.
- Nutrición: metas diarias de calorías y macros calculadas con tus datos y registro de comidas.
- Ajustes: editar perfil (nombre, correo, contraseña con confirmación, datos personales), modo claro u oscuro, cambiar objetivo, cambiar entrenador y notificaciones.
- Citas: desde "Tu Entrenador" → Agendar. Duran 1 hora, se eligen entre los horarios del entrenador y se pueden cancelar ahí mismo.
- Soporte: este chat. El botón "Hablar con una persona" crea una solicitud para el equipo y las respuestas llegan por notificación.

CAMBIO DE ENTRENADOR:
- En Ajustes → Cambiar entrenador se elige al nuevo y se envía una solicitud. El cambio NO es inmediato: el equipo debe confirmarlo.
- Si el nuevo entrenador cuesta más que el actual, hay que pagar la diferencia (Efectivo o Pago digital con QR y factura) y el equipo valida el cambio y el pago.
- Si cuesta igual o menos, no se paga nada extra pero igualmente espera la confirmación del equipo.
- Al aprobarse, las citas futuras con el entrenador anterior se cancelan.

ENTRENAMIENTO: cada día hay una rutina distinta (pecho y tríceps, espalda y bíceps, piernas y glúteos, hombros y core, cuerpo completo, cardio y core). Cada ejercicio tiene una figura animada, el botón "Ver técnica", un temporizador de descanso y, al terminar, un resumen donde se registra fatiga y agujetas. Todo se guarda en el Historial.

PANEL ADMINISTRATIVO (solo para el equipo): Resumen, Usuarios (aprobar, rechazar, suspender, revocar, cambiar rol), Suscripciones y Pagos (validar pagos con su factura), Cambios de entrenador, Vencimientos (revisar y avisar a quienes están por vencer o vencieron), Planes, Entrenadores, Grupos, Citas, Anuncios, Soporte y este Asistente.
`;
