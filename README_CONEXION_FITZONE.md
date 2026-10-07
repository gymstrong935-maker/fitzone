# FitZone — conexión Frontend Flutter + Backend Node/Express

## Flujo conectado

1. Selección de plan.
2. Registro o login con email/password.
3. Verificación de cuenta por código enviado al correo (solo registro).
4. JWT guardado en `shared_preferences`.
5. Para plan mensual/anual: selección de método de pago y creación de solicitud pendiente.
6. Onboarding completo:
   - entrenador
   - información personal
   - mediciones corporales
   - objetivo
   - nivel de experiencia
   - hábitos de entrenamiento
7. El backend guarda esos datos en los modelos existentes y asigna entrenador/grupo.
8. Al terminar, Flutter entra a la app principal.

## Backend

Ruta raíz: `backend/`

Instalar:

```bash
npm install
```

Crear `.env` a partir de `.env.example` y completar credenciales.

Inicializar planes, entrenadores y grupos:

```bash
npm run seed
```

Ejecutar:

```bash
npm run dev
```

Servidor esperado:

```text
http://localhost:4000
```

## Frontend

Ruta raíz: `fitzone_frontend/`

Instalar:

```bash
flutter pub get
```

Android Emulator:

```bash
flutter run
```

La app usa por defecto:

```text
http://10.0.2.2:4000/api
```

Para un teléfono físico en la misma red:

```bash
flutter run --dart-define=FITZONE_API_URL=http://IP_DE_TU_PC:4000/api
```

También está definido en:

`lib/core/network/api_config.dart`

## Endpoints usados por esta integración

### Auth

- `POST /api/users/register`
- `POST /api/users/login`
- `POST /api/users/verificar-cuenta`
- `POST /api/users/reenviar-codigo`
- `POST /api/users/forgot-password`

### Planes

- `GET /api/plans`

### Pago / suscripción

- `POST /api/subscriptions/cambiar-plan`
- `GET /api/subscriptions/me` queda disponible para fases siguientes.

### Entrenadores

- `GET /api/coaches`

### Onboarding

- `POST /api/onboarding`
- `GET /api/onboarding/me`

## Mapeo del onboarding

### Información personal

Flutter -> backend:

- edad -> `User.edad`
- género -> `User.genero`
- peso -> `User.peso` y `PhysicalMeasurement.peso`
- unidad -> `User.unidadPeso`
- altura -> `User.alturaCm` y `PhysicalMeasurement.altura`
- condición física -> `User.condicionFisica` / `PhysicalCondition.condicionFisica`
- motivación -> `Motivation.nivelMotivacion`
- estrés -> `Motivation.nivelEstres`
- energía -> `Motivation.nivelEnergia`
- condiciones médicas -> `User.condicionesMedicas` / `PhysicalCondition.observacionesMedicas`

### Mediciones

`PhysicalMeasurement` guarda peso, altura, IMC, circunferencias y pliegues.

Flutter guarda altura en cm; antes de enviar se convierte a metros porque el backend valida metros.

Si el usuario usa lb, Flutter convierte a kg antes de persistir.

### Objetivo

`Goal.apiValue` -> `TrainingPeriod.objetivo`.

### Experiencia

- beginner -> principiante
- intermediate -> intermedio
- advanced -> avanzado

Se guarda en `User.nivelExperiencia`, `PhysicalCondition.nivelExperiencia` y `TrainingPeriod.nivelExperiencia`.

### Hábitos

- frecuencia -> `TrainingFrequency.diasPorSemana`
- duración -> `TrainingFrequency.duracionMinutos`
- sueño -> `SleepQuality`
- actividad -> `TrainingFrequency.nivelActividad`
- disponibilidad -> `TrainingFrequency.disponibilidad`

### Entrenador

La app carga `GET /api/coaches` y utiliza el `_id` real de MongoDB. Al guardar onboarding:

- `User.entrenadorAsignado` recibe el Coach real.
- `Coach.clientesAsignados` recibe el usuario.
- Si había otro entrenador, se retira al usuario del anterior.

## Seguridad importante

El backend ya no confía en un `usuarioId` enviado por Flutter para cambiar el plan: usa `req.usuario.id` proveniente del JWT.

El onboarding tampoco recibe el `usuarioId` desde Flutter: lo obtiene del JWT.

## Credenciales

El archivo original subido contenía secretos de producción/desarrollo (`MONGO_URI`, JWT, correo, APIs, Cloudinary, etc.). No los incluyo en el paquete actualizado.

Antes de subir este proyecto a GitHub o compartirlo, rota esas credenciales y usa `.env` local.
