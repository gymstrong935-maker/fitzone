import '../api/api_client.dart';
import 'backend_models.dart';

class PlansService {
  PlansService(this._api);

  final ApiClient _api;

  Future<List<BackendPlan>> fetch() async {
    final dynamic data = await _api.get('/api/plans');
    final List<dynamic> list = data is List ? data : const <dynamic>[];
    return <BackendPlan>[
      for (final dynamic p in list)
        BackendPlan.fromJson(p as Map<String, dynamic>),
    ];
  }
}