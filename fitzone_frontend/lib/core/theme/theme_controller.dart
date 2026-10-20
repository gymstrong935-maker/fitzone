import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo claro / oscuro de toda la app (se recuerda entre sesiones).
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const String _key = 'fz_theme_light';

  bool _light = false;
  bool get isLight => _light;

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _light = prefs.getBool(_key) ?? false;
    } catch (_) {
      _light = false;
    }
    _applySystemUi();
  }

  Future<void> setLight(bool value) async {
    if (_light == value) return;
    _light = value;
    _applySystemUi();
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {
      // No pasa nada: simplemente no se recuerda.
    }
  }

  void toggle() => setLight(!_light);

  void _applySystemUi() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _light ? Brightness.dark : Brightness.light,
        statusBarBrightness: _light ? Brightness.light : Brightness.dark,
      ),
    );
  }

  // ── Matrices de color ─────────────────────────────────────────────────────

  static const List<double> _identity = <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  /// Invierte la luminosidad conservando el tono (invertir + rotar 180°).
  /// Aplicada dos veces vuelve al color original.
  static const List<double> _flip = <double>[
    0.574, -1.430, -0.144, 0, 255,
    -0.426, -0.430, -0.144, 0, 255,
    -0.426, -1.430, 0.856, 0, 255,
    0, 0, 0, 1, 0,
  ];

  /// El blanco resultante es #F1F5F9 (no blanco puro).
  static const List<double> _scale = <double>[241 / 255, 245 / 255, 249 / 255];

  static final List<double> _lightMatrix = <double>[
    for (int row = 0; row < 3; row++)
      for (int col = 0; col < 5; col++) _flip[row * 5 + col] * _scale[row],
    0, 0, 0, 1, 0,
  ];

  static List<double> _lerp(List<double> a, List<double> b, double t) =>
      <double>[for (int i = 0; i < 20; i++) a[i] + (b[i] - a[i]) * t];

  /// Filtro de toda la app (`t` = 0 oscuro … 1 claro).
  static ColorFilter filterFor(double t) =>
      ColorFilter.matrix(_lerp(_identity, _lightMatrix, t));

  /// Deshace el filtro en las fotos para que conserven sus colores.
  static ColorFilter counterFor(double t) =>
      ColorFilter.matrix(_lerp(_identity, _flip, t));
}