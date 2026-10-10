import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/models/onboarding_data.dart';
import 'onboarding_codec.dart';

class StoredSession {
  const StoredSession({required this.token, required this.userJson});

  final String token;
  final Map<String, dynamic> userJson;
}

/// Guarda en el dispositivo (localStorage en web) la sesión y el onboarding.
class SessionStorage {
  static const String _tokenKey = 'fz_token';
  static const String _userKey = 'fz_user';
  static const String _onboardingPrefix = 'fz_onboarding_';
  static const String _syncPrefix = 'fz_synced_';

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> userJson,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  Future<StoredSession?> readSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_tokenKey);
    final String? user = prefs.getString(_userKey);
    if (token == null || user == null) return null;

    try {
      final Object? decoded = jsonDecode(user);
      if (decoded is Map<String, dynamic>) {
        return StoredSession(token: token, userJson: decoded);
      }
    } catch (_) {
      // Datos dañados: se tratan como "sin sesión".
    }
    return null;
  }

  /// Borra el token y el usuario (el onboarding de cada usuario se conserva).
  Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> saveOnboarding(String userId, OnboardingData data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_onboardingPrefix$userId',
      jsonEncode(onboardingToJson(data)),
    );
  }

  Future<OnboardingData?> readOnboarding(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('$_onboardingPrefix$userId');
    if (raw == null) return null;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return onboardingFromJson(decoded);
    } catch (_) {
      // Datos dañados: se vuelve a pedir el onboarding.
    }
    return null;
  }

  // ── Qué partes del onboarding ya se enviaron al servidor ──────────────────

  Future<Set<String>> readSyncedSteps(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? list = prefs.getStringList('$_syncPrefix$userId');
    return list == null ? <String>{} : list.toSet();
  }

  Future<void> saveSyncedSteps(String userId, Set<String> steps) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_syncPrefix$userId', steps.toList());
  }
}