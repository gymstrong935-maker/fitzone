import '../api/api_client.dart';

List<Map<String, dynamic>> _list(dynamic data) => data is List
    ? <Map<String, dynamic>>[
        for (final dynamic e in data)
          if (e is Map<String, dynamic>) e,
      ]
    : const <Map<String, dynamic>>[];

Map<String, dynamic> _map(dynamic data) =>
    data is Map<String, dynamic> ? data : const <String, dynamic>{};

String _query(Map<String, String> params) => Uri(queryParameters: params).query;

/// Todas las llamadas del panel administrativo.
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  // Panel
  Future<Map<String, dynamic>> stats() async =>
      _map(await _api.get('/api/admin/stats'));

  Future<void> runExpirations() async {
    await _api.post('/api/admin/maintenance/vencimientos');
  }

  // Usuarios
  Future<Map<String, dynamic>> users({
    String q = '',
    String rol = '',
    String estado = '',
  }) async {
    final String qs = _query(<String, String>{
      'limit': '100',
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (rol.isNotEmpty) 'rol': rol,
      if (estado.isNotEmpty) 'estado': estado,
    });
    return _map(await _api.get('/api/admin/users?$qs'));
  }

  Future<Map<String, dynamic>> userDetail(String id) async =>
      _map(await _api.get('/api/admin/users/$id'));

  Future<void> updateUser(String id, Map<String, dynamic> body) async {
    await _api.put('/api/admin/users/$id', body: body);
  }

    Future<void> approveUser(String id) async {
    await _api.put('/api/admin/users/$id/aprobar');
  }

  Future<void> rejectUser(String id, {String reason = ''}) async {
    await _api.put(
      '/api/admin/users/$id/rechazar',
      body: <String, dynamic>{if (reason.trim().isNotEmpty) 'motivo': reason.trim()},
    );
  }

  // Suscripciones y pagos
  Future<List<Map<String, dynamic>>> subscriptions({String estado = ''}) async {
    final String qs = estado.isEmpty ? '' : '?${_query(<String, String>{'estado': estado})}';
    return _list(await _api.get('/api/admin/subscriptions$qs'));
  }

  Future<void> approve(String subscriptionId) async {
    await _api.put('/api/admin/subscriptions/$subscriptionId/aprobar');
  }

  Future<void> reject(String subscriptionId) async {
    await _api.put('/api/admin/subscriptions/$subscriptionId/rechazar');
  }

  // Entrenadores (endpoints públicos/admin existentes)
  Future<List<Map<String, dynamic>>> coaches() async =>
      _list(await _api.get('/api/coaches'));

  Future<void> createCoach(Map<String, dynamic> body) async {
    await _api.post('/api/coaches', body: body);
  }

  Future<void> updateCoach(String id, Map<String, dynamic> body) async {
    await _api.put('/api/coaches/$id', body: body);
  }

  Future<void> deleteCoach(String id) async {
    await _api.delete('/api/coaches/$id');
  }

  // Planes
  Future<List<Map<String, dynamic>>> plans() async =>
      _list(await _api.get('/api/admin/plans'));

  Future<void> updatePlan(String id, Map<String, dynamic> body) async {
    await _api.put('/api/admin/plans/$id', body: body);
  }

  // Grupos
  Future<List<Map<String, dynamic>>> groups() async =>
      _list(await _api.get('/api/admin/groups'));

  Future<void> saveGroup(String? id, Map<String, dynamic> body) async {
    if (id == null) {
      await _api.post('/api/admin/groups', body: body);
    } else {
      await _api.put('/api/admin/groups/$id', body: body);
    }
  }

  Future<void> deleteGroup(String id) async {
    await _api.delete('/api/admin/groups/$id');
  }

  // Citas
  Future<List<Map<String, dynamic>>> appointments({String estado = ''}) async {
    final String qs = estado.isEmpty ? '' : '?${_query(<String, String>{'estado': estado})}';
    return _list(await _api.get('/api/admin/appointments$qs'));
  }

  Future<void> cancelAppointment(String id) async {
    await _api.put('/api/appointments/$id/cancelar');
  }

  // Anuncios
  Future<int> broadcast(Map<String, dynamic> body) async {
    final Map<String, dynamic> data =
        _map(await _api.post('/api/admin/notifications', body: body));
    return (data['enviadas'] as num?)?.toInt() ?? 0;
  }

  // Soporte
  Future<List<Map<String, dynamic>>> tickets({String estado = ''}) async {
    final String qs = estado.isEmpty ? '' : '?${_query(<String, String>{'estado': estado})}';
    return _list(await _api.get('/api/admin/support$qs'));
  }

  Future<Map<String, dynamic>> ticket(String id) async =>
      _map(await _api.get('/api/admin/support/$id'));

  Future<Map<String, dynamic>> replyTicket(
    String id,
    String message, {
    String? estado,
  }) async {
    return _map(
      await _api.post(
        '/api/admin/support/$id/responder',
        body: <String, dynamic>{'mensaje': message, if (estado != null) 'estado': estado},
      ),
    );
  }

  Future<void> setTicketState(String id, String estado) async {
    await _api.put('/api/admin/support/$id/estado', body: <String, dynamic>{'estado': estado});
  }
}