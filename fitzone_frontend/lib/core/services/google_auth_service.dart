import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_exception.dart';

/// Configuración de Google Sign-In (se pasa con --dart-define).
///
///   flutter run \
///     --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com \
///     --dart-define=GOOGLE_IOS_CLIENT_ID=yyyy.apps.googleusercontent.com   (solo iOS/macOS)
///
/// GOOGLE_SERVER_CLIENT_ID es el ID de cliente **Web** de Google Cloud y debe
/// ser el mismo que `GOOGLE_SERVER_CLIENT_ID` en el .env del backend.
class GoogleAuthConfig {
  GoogleAuthConfig._();

static const String serverClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '5614844232-ar4n9p64skv3s48ilufdibmk7srj25h7.apps.googleusercontent.com',
);
  static const String iosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}

/// Obtiene el ID token de Google en el dispositivo. El backend lo valida.
class GoogleAuthService {
  GoogleAuthService();

  Future<void>? _init;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> _ensureInitialized() async {
    try {
      await (_init ??= GoogleSignIn.instance.initialize(
        serverClientId: GoogleAuthConfig.serverClientId,
        clientId: GoogleAuthConfig.iosClientId.isEmpty
            ? null
            : GoogleAuthConfig.iosClientId,
      ));
    } catch (_) {
      _init = null; // permite reintentar
      rethrow;
    }
  }

  /// Abre el selector de cuentas de Google y devuelve el ID token.
  /// Devuelve `null` si la persona cancela.
  Future<String?> pickIdToken() async {
    if (!_supported) {
      throw const ApiException(
        'El inicio de sesión con Google está disponible en la app de '
        'Android y iOS.',
      );
    }
    if (GoogleAuthConfig.serverClientId.isEmpty) {
      throw const ApiException(
        'Falta configurar GOOGLE_SERVER_CLIENT_ID (--dart-define) para '
        'usar Google.',
      );
    }

    try {
      await _ensureInitialized();
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'Google no entregó el token de sesión. Revisa la configuración '
          'del ID de cliente.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        // En Android también puede aparecer por mala configuración
        // (SHA-1 / ID de cliente): revisa este log si el selector se cierra solo.
        debugPrint('Google Sign-In cancelado: ${e.code} ${e.description}');
        return null;
      }
      debugPrint('GoogleSignInException: ${e.code} ${e.description}');
      throw ApiException(
        'No se pudo iniciar sesión con Google (${e.code.name}). '
        'Inténtalo de nuevo.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In falló: $e');
      throw const ApiException(
        'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
      );
    }
  }

  /// Cierra la sesión de Google del dispositivo (para poder elegir otra cuenta).
  Future<void> signOut() async {
    if (!_supported) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // No es crítico.
    }
  }
}
