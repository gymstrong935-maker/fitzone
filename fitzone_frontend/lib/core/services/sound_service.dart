import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Efectos de sonido del entrenamiento.
enum FzSound {
  /// Empieza la sesión.
  start('sounds/start.wav'),

  /// Ejercicio completado.
  complete('sounds/complete.wav'),

  /// Cuenta regresiva (últimos 5 segundos del descanso).
  tick('sounds/tick.wav'),

  /// Termina el descanso: a trabajar.
  go('sounds/go.wav'),

  /// Entrenamiento terminado.
  finish('sounds/finish.wav'),

  /// Toque de botón.
  tap('sounds/tap.wav');

  const FzSound(this.asset);

  /// Ruta dentro de `assets/`.
  final String asset;
}

/// Reproduce los sonidos del entrenamiento. Si el audio falla (por ejemplo en
/// una plataforma sin soporte) usa el sonido del sistema y la vibración, así
/// que nunca rompe el entrenamiento.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static const String _prefsKey = 'fz_sound_enabled';

  final Map<FzSound, AudioPlayer> _players = <FzSound, AudioPlayer>{};
  bool _enabled = true;
  bool _loaded = false;

  /// `true` = los sonidos están activados.
  bool get enabled => _enabled;

  /// Lee la preferencia guardada (silenciar / activar).
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (e) {
      debugPrint('No se pudo leer la preferencia de sonido: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (e) {
      debugPrint('No se pudo guardar la preferencia de sonido: $e');
    }
  }

  /// Suena `sound` (si los sonidos están activados) con una vibración corta
  /// que acompaña a los eventos importantes.
  Future<void> play(FzSound sound) async {
    if (!_enabled) return;

    _haptic(sound);

    try {
      AudioPlayer? player = _players[sound];
      if (player == null) {
        player = AudioPlayer();
        _players[sound] = player;
        await player.setPlayerMode(PlayerMode.lowLatency);
      }
      await player.stop();
      await player.play(AssetSource(sound.asset));
    } catch (e) {
      debugPrint('Audio no disponible, se usa el sonido del sistema: $e');
      unawaited(SystemSound.play(SystemSoundType.click));
    }
  }

  void _haptic(FzSound sound) {
    switch (sound) {
      case FzSound.tick:
      case FzSound.tap:
        unawaited(HapticFeedback.selectionClick());
      case FzSound.complete:
        unawaited(HapticFeedback.lightImpact());
      case FzSound.start:
      case FzSound.go:
      case FzSound.finish:
        unawaited(HapticFeedback.mediumImpact());
    }
  }

  /// Libera los reproductores (al cerrar sesión o salir de la app).
  Future<void> dispose() async {
    for (final AudioPlayer p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}
