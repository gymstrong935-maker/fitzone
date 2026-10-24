import 'dart:typed_data';

import '../api/api_client.dart';
import 'backend_models.dart';

class UserService {
  UserService(this._api);

  final ApiClient _api;

  /// Cambia el nombre del usuario (PUT /api/users/:id).
  Future<BackendUser> updateName({
    required String userId,
    required String name,
  }) =>
      updateProfile(userId: userId, name: name);

  /// Actualiza los datos de la cuenta que se envíen (nombre, correo, teléfono,
  /// edad, género) y, si se da, la foto de perfil.
  Future<BackendUser> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    int? age,
    String? gender,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    final Map<String, String> fields = <String, String>{
      if (name != null) 'nombre': name,
      if (email != null) 'email': email,
      if (phone != null) 'telefono': phone,
      if (age != null) 'edad': '$age',
      if (gender != null) 'genero': gender,
    };

    final dynamic data = await _api.multipart(
      'PUT',
      '/api/users/$userId',
      fields: fields,
      fileField: photoBytes == null ? null : 'imagen',
      bytes: photoBytes,
      filename: photoName,
    );
    return BackendUser.fromJson(data as Map<String, dynamic>);
  }

  /// Cambia (o crea) la contraseña. La confirmación se valida también en el servidor.
  Future<void> changePassword({
    required String userId,
    String? currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    await _api.put(
      '/api/users/$userId/password',
      body: <String, dynamic>{
        if (currentPassword != null && currentPassword.isNotEmpty)
          'passwordActual': currentPassword,
        'passwordNueva': newPassword,
        'confirmacion': confirmation,
      },
    );
  }
}
