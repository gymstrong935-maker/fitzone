// Lo que el asistente sabe de la app (además de los datos reales de la base de datos).
// Mantén esto al día cuando cambie la app.
export const CONOCIMIENTO_APP = `
CUENTA Y REGISTRO:
- Para registrarse se elige un plan (Gratuito, Mensual o Anual) y se crean nombre, correo y contraseña. Luego se verifica el correo con un código de 6 dígitos que vence en 15 minutos.
- Después de verificar el correo, el equipo de FitZone debe aprobar la cuenta. Mientras no la aprueben, la app muestra "Cuenta en revisión" y no se puede avanzar. Cuando la aprueban llega una notificación y un correo.
- Si la cuenta es rechazada, la app muestra el motivo y se puede escribir a soporte.
- Si se olvida la contraseña: en el inicio de sesión se toca "¿Olvidaste tu contraseña?" y llega un código de 6 dígitos al correo (vence en 15 minutos).

PLANES Y PAGOS:
- El plan Gratuito es una prueba de pocos días y no incluye entrenador personal. La prueba empieza a contar cuando aprueban la cuenta.
- Los planes Mensual y Anual se pagan en efectivo, con tarjeta o por medios digitales. El pago queda pendiente hasta que el equipo lo aprueba; entonces el plan se activa y llega una notificación. Mientras tanto se puede configurar el perfil.
- Los planes de pago incluyen entrenador personal.

CONFIGURACIÓN INICIAL (onboarding): elegir entrenador (solo planes de pago), información personal, mediciones corporales (opcional), objetivo, nivel de experiencia y hábitos de entrenamiento.

PANTALLAS DE LA APP:
- Inicio: rutina de hoy, progreso semanal, accesos rápidos, campana de notificaciones, asistente y tarjeta "Tu Entrenador" con botón Agendar.
- Estadísticas, Logros y Comunidad: están en desarrollo y por ahora muestran datos de ejemplo.
- Mi Plan: el plan semanal de entrenamiento.
- Historial: los entrenamientos que ya terminaste, con ejercicios, duración y calorías.
- Nutrición: metas diarias de calorías y macros calculadas con tus datos (peso, estatura, edad, actividad y objetivo) y registro de comidas con el botón Agregar.
- Ajustes: editar perfil (nombre), modo claro u oscuro, cambiar objetivo, cambiar entrenador y notificaciones.
- Citas: desde "Tu Entrenador" → Agendar. Duran 1 hora, se eligen entre los horarios del entrenador y se pueden cancelar ahí mismo.
- Soporte: este chat. El botón "Hablar con una persona" crea una solicitud para el equipo y las respuestas llegan por notificación.

ENTRENAMIENTO: cada día hay una rutina distinta (pecho y tríceps, espalda y bíceps, piernas y glúteos, hombros y core, cuerpo completo, cardio y core). Cada ejercicio tiene una figura animada, el botón "Ver técnica", un temporizador de descanso y, al terminar, un resumen donde se registra fatiga y agujetas. Todo se guarda en el Historial.
`;