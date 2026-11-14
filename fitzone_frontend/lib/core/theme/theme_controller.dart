import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo claro / oscuro de toda la app (se recuerda entre sesiones).
///
/// Los colores salen de `AppColors`, que lee [isLight]. Al cambiar de modo se
/// avisa a los oyentes y se fuerza un redibujado completo del árbol de widgets
/// (sin perder el estado de ninguna pantalla).
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
    _rebuildAll();
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
        systemNavigationBarColor: _light ? const Color(0xFFF4F7FB) : Colors.black,
        systemNavigationBarIconBrightness:
            _light ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// Marca todos los elementos para reconstruirse en el siguiente frame,
  /// de modo que los colores calculados en `build` se lean otra vez.
  void _rebuildAll() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    final Element? root = WidgetsBinding.instance.rootElement;
    root?.visitChildren(visit);
  }
}
