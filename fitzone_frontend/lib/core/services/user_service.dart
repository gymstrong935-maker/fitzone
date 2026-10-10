import '../api/api_client.dart';
import 'backend_models.dart';

class UserService {
  UserService(this._api);

  final ApiClient _api;

  /// Cambia el nombre del usuario (PUT /api/users/:id).
  Future<BackendUser> updateName({
    required String userId,
    required String name,
  }) async {
    final dynamic data = await _api.put(
      '/api/users/$userId',
      body: <String, dynamic>{'nombre': name},
    );
    return BackendUser.fromJson(data as Map<String, dynamic>);
  }
}