import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/plan.dart';

class PlanService {
  static const String baseUrl =
      'http://10.0.2.2:4000/api';

  static Future<List<Plan>> obtenerPlanes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/plans'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> datos =
          jsonDecode(response.body);

      return datos.map((plan) {
        return Plan.fromJson(plan);
      }).toList();
    } else {
      throw Exception(
        'No se pudieron cargar los planes',
      );
    }
  }
}