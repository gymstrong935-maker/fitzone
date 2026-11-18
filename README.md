FITZONE APP 🏋️

Aplicación móvil y sistema de gestión para el gimnasio Strong Gym, orientado a digitalizar el entrenamiento de los usuarios y la administración del negocio.

FITZONE APP es una solución tecnológica desarrollada para modernizar la gestión del gimnasio y mejorar la experiencia de sus afiliados.

La aplicación permite a los usuarios registrarse, definir sus objetivos, elegir un entrenador y un plan de membresía, seguir su plan de entrenamiento, registrar su alimentación, agendar citas, consultar su progreso y participar en la comunidad del gimnasio.

Por otra parte, el sistema proporciona un panel de administración para la gestión de usuarios, planes, pagos, vencimientos, entrenadores, grupos, citas, anuncios, soporte y actividad.

Mostrar imagen

📲 Descarga la app (Android)

👉 Ir a la última versión (Releases)

⬇️ Descargar APK v1.0.0

Cómo instalar
Abre el enlace de arriba desde tu celular Android.
En la sección Assets descarga el archivo .apk.
Ábrelo y, si el teléfono lo pide, permite "Instalar apps de fuentes desconocidas".
Instala y abre FitZone.

Requiere Android y conexión a internet. Google Play Protect puede mostrar una advertencia porque la app no se distribuye desde Play Store: elige "Instalar de todos modos".

El servidor está en Render: la primera carga puede tardar unos segundos si estuvo inactivo.

💻 Stack tecnológico
Frontend
Flutter — Desarrollo de la aplicación móvil.
Dart — Lenguaje de programación utilizado por Flutter.
HTTP/REST — Comunicación entre la aplicación y el backend.
JSON — Formato utilizado para el intercambio de información.
Google Sign-In — Inicio de sesión con cuenta de Google.
Google Fonts, flutter_svg y audioplayers — Tipografía, gráficos vectoriales y sonidos de la app.
flutter_tts — Lectura por voz del asistente.
Backend
Node.js — Entorno de ejecución de JavaScript.
Express.js — Framework utilizado para desarrollar la API REST.
Mongoose — ODM para la comunicación y gestión de datos en MongoDB.
JWT (JSON Web Token) — Autenticación y autorización de usuarios.
Zod — Validación de los datos que recibe la API.
bcrypt — Cifrado de contraseñas.
express-rate-limit — Límite de peticiones para proteger la API.
node-cron — Tareas programadas, como la revisión de vencimientos de membresías.
Multer y Cloudinary — Carga y almacenamiento de imágenes (por ejemplo, comprobantes de pago).
Brevo y Nodemailer — Envío de correos de verificación y recuperación de contraseña.
Groq — Modelo de lenguaje del asistente virtual.
Base de datos
MongoDB — Sistema de gestión de base de datos NoSQL.
MongoDB Atlas — Servicio utilizado para alojar la base de datos en la nube.
Despliegue y herramientas
Render — Alojamiento del backend.
Git y GitHub — Control de versiones y trabajo colaborativo.
Visual Studio Code — Editor de código.
Android Studio — Desarrollo, emulación y herramientas para Android.
✨ Características del proyecto
Gestión de usuarios
Registro e inicio de sesión (correo y Google).
Verificación de correo y recuperación de contraseña.
Autenticación y autorización por roles.
Gestión y edición del perfil.
Onboarding y membresía
Definición de objetivos, nivel de experiencia y hábitos de entrenamiento.
Registro de medidas corporales con guías de medición.
Elección de entrenador.
Selección de plan de membresía.
Pago en efectivo o digital (QR Bre-B con carga de comprobante) y validación del pago.
Entrenamiento
Plan de entrenamiento con calendario, mesociclos y rutinas del día.
Entrenamiento guiado con técnica de ejercicios, temporizador de descanso y resumen de la sesión.
Historial de entrenamientos.
Estadísticas con gráficas.
Logros.
Nutrición y bienestar
Registro de comidas y control de macronutrientes.
Citas
Agendamiento de citas con entrenadores.
Solicitud de cambio de entrenador.
Comunidad
Publicaciones e interacción entre los afiliados del gimnasio.
Notificaciones
Notificaciones dentro de la app sobre pagos, vencimientos y novedades.
Asistente virtual
Asistente con inteligencia artificial y lectura por voz.
Soporte
Solicitudes de ayuda desde la app.
Administración
Gestión de usuarios.
Gestión de planes y pagos.
Control de vencimientos de membresías.
Gestión de entrenadores y cambios de entrenador.
Gestión de grupos.
Gestión de citas.
Publicación de anuncios.
Atención de solicitudes de soporte.
Registro de actividad.
⚙️ Instalación y configuración
Requisitos previos

Antes de instalar el proyecto, cada integrante del equipo debe contar con las siguientes herramientas:

Git
Node.js
npm
Flutter SDK
Dart SDK
Acceso a MongoDB Atlas (o MongoDB local)
Visual Studio Code
Android Studio
Un dispositivo Android o un emulador Android

Se recomienda verificar que las herramientas estén disponibles desde la terminal:

bash
git --version
node --version
npm --version
flutter --version
dart --version
1. Clonar el repositorio
bash
git clone https://github.com/gymstrong935-maker/fitzone.git
cd fitzone
2. Configuración del Backend

Ingresar a la carpeta del backend e instalar las dependencias:

bash
cd backend
npm install

Crear un archivo .env dentro de backend/ con las siguientes variables:

env
PORT=4000
NODE_ENV=development
MONGO_URI=tu_cadena_de_conexion_de_mongodb
JWT_SECRET=una_clave_secreta_larga
APP_URL=url_publica_del_backend
TZ_GIMNASIO=America/Bogota

# Imágenes (comprobantes de pago)
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret

# Correo (verificación y recuperación de contraseña)
BREVO_API_KEY=tu_api_key_de_brevo
EMAIL_USER=correo_remitente
EMAIL_PASS=clave_del_correo

# Inicio de sesión con Google
GOOGLE_WEB_CLIENT_ID=tu_client_id_web
GOOGLE_ANDROID_CLIENT_ID=tu_client_id_android
GOOGLE_SERVER_CLIENT_ID=tu_client_id_web

# Asistente virtual
GROQ_API_KEY=tu_api_key_de_groq

El archivo .env contiene datos sensibles y no se sube al repositorio (está en .gitignore).

Cargar los datos iniciales (planes, grupos y entrenadores):

bash
npm run seed
npm run seed:coaches
Ejecutar el backend

Desde la carpeta backend:

bash
npm start

Para desarrollo con recarga automática (Nodemon):

bash
npm run dev

Una vez iniciado, la API estará disponible en:

http://localhost:4000

Para comprobar que funciona, abre http://localhost:4000/health.

3. Configuración del Frontend

Desde la raíz del proyecto ingresar a la carpeta de Flutter:

bash
cd fitzone_frontend

Instalar las dependencias:

bash
flutter pub get

Verificar los dispositivos disponibles:

bash
flutter devices

Ejecutar la aplicación (usa por defecto el backend desplegado en Render):

bash
flutter run

Para ejecutar específicamente en Android:

bash
flutter run -d android
Usar el backend local

Por defecto la app se conecta al servidor de Render. Para apuntar a tu backend local, indica la URL al ejecutar:

bash
flutter run --dart-define=API_URL=http://10.0.2.2:4000

10.0.2.2 es la dirección con la que el emulador de Android accede al localhost de tu computador. En un celular físico usa la IP local de tu computador.

Inicio de sesión con Google

Para que funcione el acceso con Google, pasa el ID de cliente web al ejecutar:

bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com

Debe ser el mismo valor de GOOGLE_SERVER_CLIENT_ID del .env del backend.

4. Generar el APK (release)

Desde la carpeta fitzone_frontend:

bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com

El APK queda en fitzone_frontend/build/app/outputs/flutter-apk/app-release.apk.

Las claves, el keystore y los archivos .env no se suben al repositorio.

Publicar una nueva versión
Genera el APK y renómbralo, por ejemplo FitZone-v1.0.1.apk.
En GitHub: Releases → Draft a new release, crea el tag v1.0.1 y adjunta el APK.
Publícalo como Latest release (no como Pre-release).
Calcula el SHA-256 del APK (certutil -hashfile FitZone-v1.0.1.apk SHA256 en Windows) y agrégalo a las notas del release.
🏗️ Arquitectura del proyecto

FITZONE APP utiliza una arquitectura dividida principalmente en Frontend, Backend y Base de Datos.

                      FITZONE APP
                           │
             ┌─────────────┴─────────────┐
             │                           │
         FRONTEND                    BACKEND
         Flutter                    Node.js
         Dart                       Express
             │                           │
             │        HTTP / REST        │
             └─────────────┬─────────────┘
                           │
                           ▼
                       MongoDB
                    MongoDB Atlas
Frontend

El frontend es responsable de la interfaz visual y de la interacción con los usuarios. Está organizado por funcionalidades.

fitzone_frontend/
│
├── lib/
│   ├── core/
│   │   ├── api/          # Cliente HTTP y configuración de la API
│   │   ├── models/       # Modelos compartidos
│   │   ├── services/     # Servicios que consumen el backend
│   │   ├── session/      # Manejo de la sesión del usuario
│   │   ├── theme/        # Colores y estilos
│   │   ├── utils/
│   │   └── widgets/      # Widgets reutilizables
│   │
│   ├── features/
│   │   ├── auth/         # Registro, inicio de sesión y recuperación
│   │   ├── onboarding/   # Objetivos, hábitos y medidas
│   │   ├── plan_selection/ y payment_method/   # Planes y pagos
│   │   ├── plan/         # Plan de entrenamiento y calendario
│   │   ├── workout/      # Entrenamiento guiado
│   │   ├── history/ y stats/ y achievements/   # Progreso
│   │   ├── nutrition/    # Control de nutrición
│   │   ├── appointments/ # Citas
│   │   ├── community/    # Comunidad
│   │   ├── assistant/    # Asistente virtual
│   │   ├── notifications/ y support/ y settings/
│   │   └── admin/        # Panel de administración
│   │
│   └── main.dart
│
├── assets/               # Imágenes, íconos y sonidos
└── pubspec.yaml
Backend

El backend contiene la lógica de negocio y funciona como intermediario entre Flutter y MongoDB.

backend/
│
├── src/
│   ├── controllers/   # Lógica de cada módulo
│   ├── models/        # Esquemas de Mongoose
│   ├── routes/        # Rutas de la API
│   ├── middleware/    # Autenticación, validación, límites y auditoría
│   ├── validators/    # Esquemas de validación (Zod)
│   ├── helpers/       # Suscripciones, vencimientos y notificaciones
│   ├── jobs/          # Tareas programadas
│   ├── config/        # Conexión a la base de datos
│   └── scripts/       # Scripts de mantenimiento
│
├── .env
├── server.js
└── package.json
👥 Autores

Proyecto desarrollado por:

Integrante	Rol
Yasmin Lorena Velez Falla	(analistica de frontend, versiones de git hub y pruebas)
Lizeth Zamara Velez Falla	(lider, desarrolladora de backend, base de datos y implemntacion/dezspliegeue)

Proyecto ADSO — SENA, Garzón. Cliente: Strong Gym.
