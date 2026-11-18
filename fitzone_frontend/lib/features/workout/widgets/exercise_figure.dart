import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';

/// Figura animada de un ejercicio (lienzo de 130 x 160 unidades escalado al
/// tamaño pedido).
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({super.key, required this.exerciseId, this.size = 160});

  final String exerciseId;
  final double size;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration elapsed) {
      _seconds.value = elapsed.inMicroseconds / 1000000.0;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _FigurePainter(
          exerciseId: widget.exerciseId,
          seconds: _seconds,
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({required this.exerciseId, required this.seconds})
      : super(repaint: seconds);

  final String exerciseId;
  final ValueListenable<double> seconds;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    // viewBox 130 x 160, centrado y ajustado a la altura.
    final double scale = size.height / 160;
    canvas.translate((size.width - 130 * scale) / 2, 0);
    canvas.scale(scale);

    final _Spec spec = _specs[exerciseId] ?? _fallback;
    spec.paint(canvas, seconds.value);
  }

  @override
  bool shouldRepaint(covariant _FigurePainter oldDelegate) =>
      oldDelegate.exerciseId != exerciseId;
}

// ═══════════════════════════════════════════════════════════════════════════
// Utilidades de animación
// ═══════════════════════════════════════════════════════════════════════════

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _phase(double seconds, double period) => (seconds % period) / period;

/// 0 → 1 durante `ratio` del ciclo y 1 → 0 el resto.
double _wave(double phase, double ratio, Curve curve) {
  if (phase < ratio) return curve.transform(phase / ratio);
  return curve.transform(1 - (phase - ratio) / (1 - ratio));
}

Offset _dir(double degrees) {
  final double r = degrees * math.pi / 180;
  return Offset(math.sin(r), math.cos(r));
}

void _stroke(Canvas c, List<Offset> points, double width, Color color) {
  final Path path = Path()..moveTo(points.first.dx, points.first.dy);
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Esqueleto (cinemática inversa de 2 huesos)
// ═══════════════════════════════════════════════════════════════════════════

const double _ua = 23; // brazo
const double _fa = 21; // antebrazo
const double _th = 36; // muslo
const double _sh = 36; // pantorrilla
const double _lt = 38; // torso
const double _neck = 15; // hombro → centro de la cabeza
const double _footLen = 10;

/// Dado un extremo fijo (cadera u hombro) y un objetivo (pie o mano), calcula
/// la articulación del medio (rodilla o codo). `side` elige hacia qué lado se dobla.
(Offset, Offset) _ik(Offset root, Offset target, double l1, double l2, int side) {
  final Offset delta = target - root;
  final double d = delta.distance;
  final double dMax = l1 + l2 - 0.01;
  final double dMin = (l1 - l2).abs() + 0.01;
  final double dc = d.clamp(dMin, dMax).toDouble();
  final Offset u = d < 1e-6 ? const Offset(0, 1) : delta / d;
  final double a = (l1 * l1 - l2 * l2 + dc * dc) / (2 * dc);
  final double h = math.sqrt(math.max(0.0, l1 * l1 - a * a));
  final Offset mid = root + u * a + Offset(-u.dy, u.dx) * (h * side);
  final Offset end = root + u * dc;
  return (mid, end);
}

/// Pose de perfil (mirando a la derecha).
class _SidePose {
  const _SidePose({
    required this.hip,
    required this.torso,
    required this.handN,
    required this.handF,
    required this.footN,
    required this.footF,
    required this.rel,
    required this.kneeN,
    required this.kneeF,
    required this.elbowN,
    required this.elbowF,
    required this.tilt,
    required this.footAngle,
  });

  /// Cadera.
  final Offset hip;

  /// Ángulo del torso (0 = hacia abajo, 90 = derecha, 180 = arriba).
  final double torso;

  /// Mano cercana y lejana (relativas al hombro si [rel]).
  final Offset handN;
  final Offset handF;

  /// Tobillo cercano y lejano.
  final Offset footN;
  final Offset footF;
  final bool rel;

  /// Hacia qué lado se doblan rodillas y codos (+1 / -1).
  final int kneeN;
  final int kneeF;
  final int elbowN;
  final int elbowF;

  /// Inclinación de la cabeza respecto al torso.
  final double tilt;

  /// Ángulo del pie (90 = apoyado plano hacia la derecha).
  final double footAngle;
}

_SidePose _mix(_SidePose a, _SidePose b, double t) {
  return _SidePose(
    hip: Offset.lerp(a.hip, b.hip, t)!,
    torso: _lerp(a.torso, b.torso, t),
    handN: Offset.lerp(a.handN, b.handN, t)!,
    handF: Offset.lerp(a.handF, b.handF, t)!,
    footN: Offset.lerp(a.footN, b.footN, t)!,
    footF: Offset.lerp(a.footF, b.footF, t)!,
    rel: a.rel,
    kneeN: a.kneeN,
    kneeF: a.kneeF,
    elbowN: a.elbowN,
    elbowF: a.elbowF,
    tilt: _lerp(a.tilt, b.tilt, t),
    footAngle: _lerp(a.footAngle, b.footAngle, t),
  );
}

class _Joints {
  const _Joints({
    required this.hip,
    required this.shoulder,
    required this.head,
    required this.elbowN,
    required this.wristN,
    required this.elbowF,
    required this.wristF,
    required this.kneeN,
    required this.ankleN,
    required this.kneeF,
    required this.ankleF,
    required this.toeN,
    required this.toeF,
  });

  final Offset hip;
  final Offset shoulder;
  final Offset head;
  final Offset elbowN;
  final Offset wristN;
  final Offset elbowF;
  final Offset wristF;
  final Offset kneeN;
  final Offset ankleN;
  final Offset kneeF;
  final Offset ankleF;
  final Offset toeN;
  final Offset toeF;
}

_Joints _solve(_SidePose p) {
  final Offset shoulder = p.hip + _dir(p.torso) * _lt;
  final Offset head = shoulder + _dir(p.torso + p.tilt) * _neck;
  final Offset handN = p.rel ? shoulder + p.handN : p.handN;
  final Offset handF = p.rel ? shoulder + p.handF : p.handF;

  final (Offset elbowN, Offset wristN) = _ik(shoulder, handN, _ua, _fa, p.elbowN);
  final (Offset elbowF, Offset wristF) = _ik(shoulder, handF, _ua, _fa, p.elbowF);
  final (Offset kneeN, Offset ankleN) = _ik(p.hip, p.footN, _th, _sh, p.kneeN);
  final (Offset kneeF, Offset ankleF) = _ik(p.hip, p.footF, _th, _sh, p.kneeF);

  final Offset toe = _dir(p.footAngle) * _footLen;

  return _Joints(
    hip: p.hip,
    shoulder: shoulder,
    head: head,
    elbowN: elbowN,
    wristN: wristN,
    elbowF: elbowF,
    wristF: wristF,
    kneeN: kneeN,
    ankleN: ankleN,
    kneeF: kneeF,
    ankleF: ankleF,
    toeN: ankleN + toe,
    toeF: ankleF + toe,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Utilería (barras, discos, mancuernas, banco...)
// ═══════════════════════════════════════════════════════════════════════════

enum _Prop { none, bench, rack, plate9, plate11, plate8, pullBar, dumbbellH, dumbbellV, dipBench, mat }

void _plate(Canvas c, Offset center, double r) {
  c.drawCircle(center, r, Paint()..color = AppColors.cyan.withAlpha(150));
  c.drawCircle(
    center,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.cyan,
  );
  c.drawCircle(center, r * 0.35, Paint()..color = const Color(0xFF0A0A12));
}

void _dumbbell(Canvas c, Offset center, {required bool vertical}) {
  final Offset axis = vertical ? const Offset(0, 1) : const Offset(1, 0);
  _stroke(c, <Offset>[center - axis * 6, center + axis * 6], 4, AppColors.cyan);
  for (final double s in <double>[-7, 7]) {
    c.drawCircle(center + axis * s, 3.6, Paint()..color = AppColors.cyan.withAlpha(170));
  }
}

void _paintProp(Canvas c, _Prop prop, Offset wrist, {required bool back}) {
  final Color metal = AppColors.whiteA(0.20);
  final Color light = AppColors.whiteA(0.45);

  switch (prop) {
    case _Prop.none:
      return;
    case _Prop.bench:
      if (back) {
        _stroke(c, const <Offset>[Offset(24, 118), Offset(108, 118)], 9, metal);
        _stroke(c, const <Offset>[Offset(30, 122), Offset(26, 146)], 4, metal);
        _stroke(c, const <Offset>[Offset(102, 122), Offset(106, 146)], 4, metal);
        _stroke(c, const <Offset>[Offset(100, 118), Offset(100, 58)], 4, metal);
      } else {
        _plate(c, wrist, 9);
      }
    case _Prop.rack:
      if (back) {
        _stroke(c, const <Offset>[Offset(112, 40), Offset(112, 152)], 4, metal);
        _stroke(c, const <Offset>[Offset(104, 50), Offset(112, 50)], 3, metal);
      } else {
        _plate(c, wrist, 9);
      }
    case _Prop.plate9:
      if (!back) _plate(c, wrist, 9);
    case _Prop.plate11:
      if (!back) _plate(c, wrist, 11);
    case _Prop.plate8:
      if (!back) _plate(c, wrist, 8);
    case _Prop.pullBar:
      if (back) {
        _stroke(c, const <Offset>[Offset(20, 22), Offset(110, 22)], 5, light);
        _stroke(c, const <Offset>[Offset(22, 22), Offset(22, 6)], 4, metal);
        _stroke(c, const <Offset>[Offset(108, 22), Offset(108, 6)], 4, metal);
      }
    case _Prop.dumbbellH:
      if (!back) _dumbbell(c, wrist, vertical: false);
    case _Prop.dumbbellV:
      if (!back) _dumbbell(c, wrist, vertical: true);
    case _Prop.dipBench:
      if (back) {
        _stroke(c, const <Offset>[Offset(6, 104), Offset(32, 104)], 8, metal);
        _stroke(c, const <Offset>[Offset(10, 108), Offset(10, 118)], 4, metal);
        _stroke(c, const <Offset>[Offset(28, 108), Offset(28, 118)], 4, metal);
      }
    case _Prop.mat:
      if (back) {
        _stroke(c, const <Offset>[Offset(8, 150), Offset(118, 150)], 5, AppColors.whiteA(0.12));
      }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Especificaciones de animación
// ═══════════════════════════════════════════════════════════════════════════

abstract class _Spec {
  const _Spec();

  void paint(Canvas canvas, double seconds);
}

class _Fit {
  const _Fit(this.scale, this.dx, this.dy);

  final double scale;
  final double dx;
  final double dy;
}

const _Fit _tall = _Fit(0.86, 9, 21);
const _Fit _wide = _Fit(0.85, 5, 10);
const _Fit _benchFit = _Fit(0.9, 6, 5);

class _SideSpec extends _Spec {
  const _SideSpec({
    required this.a,
    required this.b,
    required this.period,
    this.ratio = 0.45,
    this.curve = Curves.easeInOut,
    this.fit = _tall,
    this.hlArms = false,
    this.hlLegs = false,
    this.hlCore = false,
    this.prop = _Prop.none,
    this.ground = 155,
  });

  final _SidePose a;
  final _SidePose b;
  final double period;
  final double ratio;
  final Curve curve;
  final _Fit fit;
  final bool hlArms;
  final bool hlLegs;
  final bool hlCore;
  final _Prop prop;

  /// Altura del piso (negativo = sin piso).
  final double ground;

  @override
  void paint(Canvas canvas, double seconds) {
    final double p = _wave(_phase(seconds, period), ratio, curve);
    final _Joints j = _solve(_mix(a, b, p));

    final Color near = AppColors.whiteA(0.34);
    final Color far = AppColors.whiteA(0.15);
    final Color torsoColor = AppColors.whiteA(0.17);
    final Color hl = AppColors.cyan.withAlpha(230);

    canvas.save();
    canvas.translate(fit.dx, fit.dy);
    canvas.scale(fit.scale);

    if (ground >= 0) {
      _stroke(
        canvas,
        <Offset>[Offset(-30, ground), Offset(160, ground)],
        1.2,
        AppColors.whiteA(0.10),
      );
    }

    _paintProp(canvas, prop, j.wristN, back: true);

    // Extremidades lejanas
    _stroke(canvas, <Offset>[j.hip, j.kneeF, j.ankleF, j.toeF], 7.5, far);
    _stroke(canvas, <Offset>[j.shoulder, j.elbowF, j.wristF], 5.5, far);

    // Torso y cabeza
    _stroke(canvas, <Offset>[j.hip, j.shoulder], 15, hlCore ? hl : torsoColor);
    canvas.drawCircle(j.head, 9, Paint()..color = AppColors.whiteA(0.14));
    canvas.drawCircle(
      j.head,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.whiteA(0.30),
    );

    // Extremidades cercanas
    _stroke(canvas, <Offset>[j.hip, j.kneeN, j.ankleN, j.toeN], 8, hlLegs ? hl : near);
    _stroke(canvas, <Offset>[j.shoulder, j.elbowN, j.wristN], 6, hlArms ? hl : near);

    _paintProp(canvas, prop, j.wristN, back: false);

    canvas.restore();
  }
}

/// Pose de frente (para elevaciones laterales y jumping jacks).
class _FrontPose {
  const _FrontPose({
    required this.hipY,
    required this.handL,
    required this.handR,
    required this.footL,
    required this.footR,
  });

  final double hipY;
  final Offset handL;
  final Offset handR;
  final Offset footL;
  final Offset footR;
}

_FrontPose _mixFront(_FrontPose a, _FrontPose b, double t) => _FrontPose(
      hipY: _lerp(a.hipY, b.hipY, t),
      handL: Offset.lerp(a.handL, b.handL, t)!,
      handR: Offset.lerp(a.handR, b.handR, t)!,
      footL: Offset.lerp(a.footL, b.footL, t)!,
      footR: Offset.lerp(a.footR, b.footR, t)!,
    );

class _FrontSpec extends _Spec {
  const _FrontSpec({
    required this.a,
    required this.b,
    required this.period,
    this.ratio = 0.45,
    this.curve = Curves.easeInOut,
    this.dumbbells = false,
    this.hlArms = false,
    this.hlLegs = false,
  });

  final _FrontPose a;
  final _FrontPose b;
  final double period;
  final double ratio;
  final Curve curve;
  final bool dumbbells;
  final bool hlArms;
  final bool hlLegs;

  static const double _cx = 65;

  @override
  void paint(Canvas canvas, double seconds) {
    final double p = _wave(_phase(seconds, period), ratio, curve);
    final _FrontPose pose = _mixFront(a, b, p);

    final Offset hip = Offset(_cx, pose.hipY);
    final Offset chest = Offset(_cx, pose.hipY - _lt);
    final Offset head = Offset(_cx, pose.hipY - _lt - _neck);
    final Offset shL = Offset(_cx - 12, pose.hipY - _lt + 2);
    final Offset shR = Offset(_cx + 12, pose.hipY - _lt + 2);
    final Offset hipL = Offset(_cx - 6, pose.hipY);
    final Offset hipR = Offset(_cx + 6, pose.hipY);

    final (Offset elbowL, Offset wristL) = _ik(shL, pose.handL, _ua, _fa, 1);
    final (Offset elbowR, Offset wristR) = _ik(shR, pose.handR, _ua, _fa, -1);
    final (Offset kneeL, Offset ankleL) = _ik(hipL, pose.footL, _th, _sh, 1);
    final (Offset kneeR, Offset ankleR) = _ik(hipR, pose.footR, _th, _sh, -1);

    final Color near = AppColors.whiteA(0.34);
    final Color torsoColor = AppColors.whiteA(0.17);
    final Color hl = AppColors.cyan.withAlpha(230);

    canvas.save();
    canvas.translate(_tall.dx, _tall.dy);
    canvas.scale(_tall.scale);

    _stroke(
      canvas,
      const <Offset>[Offset(-30, 155), Offset(160, 155)],
      1.2,
      AppColors.whiteA(0.10),
    );

    final Color legColor = hlLegs ? hl : near;
    _stroke(canvas, <Offset>[hipL, kneeL, ankleL, ankleL + const Offset(-6, 3)], 8, legColor);
    _stroke(canvas, <Offset>[hipR, kneeR, ankleR, ankleR + const Offset(6, 3)], 8, legColor);

    _stroke(canvas, <Offset>[hip, chest], 22, torsoColor);
    _stroke(canvas, <Offset>[shL, shR], 9, torsoColor);

    canvas.drawCircle(head, 9, Paint()..color = AppColors.whiteA(0.14));
    canvas.drawCircle(
      head,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.whiteA(0.30),
    );

    final Color armColor = hlArms ? hl : near;
    _stroke(canvas, <Offset>[shL, elbowL, wristL], 6, armColor);
    _stroke(canvas, <Offset>[shR, elbowR, wristR], 6, armColor);

    if (dumbbells) {
      _dumbbell(canvas, wristL, vertical: true);
      _dumbbell(canvas, wristR, vertical: true);
    }

    canvas.restore();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Poses de perfil (generadas y comprobadas visualmente)
// ═══════════════════════════════════════════════════════════════════════════

class _P {
  _P._();

  static const _SidePose bA = _SidePose(
    hip: Offset(46.0, 108.0), torso: 90.0,
    handN: Offset(70.0, 92.0), handF: Offset(70.0, 92.0),
    footN: Offset(12.0, 142.0), footF: Offset(10.0, 142.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose bB = _SidePose(
    hip: Offset(46.0, 108.0), torso: 90.0,
    handN: Offset(84.0, 64.0), handF: Offset(84.0, 64.0),
    footN: Offset(12.0, 142.0), footF: Offset(10.0, 142.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose sqA = _SidePose(
    hip: Offset(62.0, 80.0), torso: 178.0,
    handN: Offset(-8.0, -3.0), handF: Offset(-8.0, -3.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose sqB = _SidePose(
    hip: Offset(38.0, 110.0), torso: 150.0,
    handN: Offset(-8.0, -3.0), handF: Offset(-8.0, -3.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose prA = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(8.0, -2.0), handF: Offset(8.0, -2.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose prB = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(2.0, -43.0), handF: Offset(2.0, -43.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose dlA = _SidePose(
    hip: Offset(36.0, 118.0), torso: 118.0,
    handN: Offset(66.0, 143.0), handF: Offset(66.0, 143.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose dlB = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(64.0, 86.0), handF: Offset(64.0, 86.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose puA = _SidePose(
    hip: Offset(62.0, 104.0), torso: 180.0,
    handN: Offset(62.0, 22.0), handF: Offset(62.0, 22.0),
    footN: Offset(54.0, 140.0), footF: Offset(58.0, 140.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose puB = _SidePose(
    hip: Offset(58.0, 72.0), torso: 172.0,
    handN: Offset(62.0, 22.0), handF: Offset(62.0, 22.0),
    footN: Offset(50.0, 106.0), footF: Offset(54.0, 106.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose cuA = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(6.0, 44.0), handF: Offset(6.0, 44.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose cuB = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(13.0, 5.0), handF: Offset(6.0, 44.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose diA = _SidePose(
    hip: Offset(41.7, 94.0), torso: 198.0,
    handN: Offset(28.0, 102.0), handF: Offset(28.0, 102.0),
    footN: Offset(112.0, 114.0), footF: Offset(116.0, 114.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose diB = _SidePose(
    hip: Offset(48.7, 108.0), torso: 198.0,
    handN: Offset(28.0, 102.0), handF: Offset(28.0, 102.0),
    footN: Offset(112.0, 114.0), footF: Offset(116.0, 114.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose fxA = _SidePose(
    hip: Offset(69.9, 119.2), torso: 113.6,
    handN: Offset(104.8, 148.0), handF: Offset(104.8, 148.0),
    footN: Offset(4.0, 148.0), footF: Offset(4.0, 148.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: -30.0, footAngle: 60.0,
  );
  static const _SidePose fxB = _SidePose(
    hip: Offset(75.0, 136.5), torso: 99.2,
    handN: Offset(104.8, 148.0), handF: Offset(104.8, 148.0),
    footN: Offset(4.0, 148.0), footF: Offset(4.0, 148.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: -30.0, footAngle: 60.0,
  );
  static const _SidePose znA = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(3.0, 40.0), handF: Offset(3.0, 40.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose znB = _SidePose(
    hip: Offset(60.0, 112.0), torso: 180.0,
    handN: Offset(3.0, 40.0), handF: Offset(3.0, 40.0),
    footN: Offset(90.0, 151.0), footF: Offset(28.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose reA = _SidePose(
    hip: Offset(40.0, 98.0), torso: 115.0,
    handN: Offset(76.0, 126.0), handF: Offset(76.0, 126.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose reB = _SidePose(
    hip: Offset(40.0, 98.0), torso: 115.0,
    handN: Offset(60.0, 100.0), handF: Offset(60.0, 100.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: false, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose trA = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(-9.0, -5.0), handF: Offset(-9.0, -5.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose trB = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(1.0, -43.0), handF: Offset(1.0, -43.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: -1, elbowF: -1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose abA = _SidePose(
    hip: Offset(46.0, 138.0), torso: 90.0,
    handN: Offset(12.0, -6.0), handF: Offset(12.0, -6.0),
    footN: Offset(18.0, 146.0), footF: Offset(22.0, 146.0),
    rel: true, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose abB = _SidePose(
    hip: Offset(46.0, 138.0), torso: 128.0,
    handN: Offset(12.0, -8.0), handF: Offset(12.0, -8.0),
    footN: Offset(18.0, 146.0), footF: Offset(22.0, 146.0),
    rel: true, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: -25.0, footAngle: 90.0,
  );
  static const _SidePose plA = _SidePose(
    hip: Offset(74.3, 133.0), torso: 102.0,
    handN: Offset(132.0, 148.0), handF: Offset(132.0, 148.0),
    footN: Offset(4.0, 148.0), footF: Offset(4.0, 148.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: -20.0, footAngle: 60.0,
  );
  static const _SidePose plB = _SidePose(
    hip: Offset(74.0, 131.8), torso: 103.0,
    handN: Offset(132.0, 148.0), handF: Offset(132.0, 148.0),
    footN: Offset(4.0, 148.0), footF: Offset(4.0, 148.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: -20.0, footAngle: 60.0,
  );
  static const _SidePose pnA = _SidePose(
    hip: Offset(46.0, 140.0), torso: 90.0,
    handN: Offset(-40.0, 8.0), handF: Offset(-40.0, 8.0),
    footN: Offset(20.0, 148.0), footF: Offset(20.0, 148.0),
    rel: true, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose pnB = _SidePose(
    hip: Offset(52.0, 104.0), torso: 52.0,
    handN: Offset(-40.0, 10.0), handF: Offset(-40.0, 10.0),
    footN: Offset(22.0, 148.0), footF: Offset(22.0, 148.0),
    rel: true, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose caA = _SidePose(
    hip: Offset(62.0, 80.0), torso: 180.0,
    handN: Offset(5.0, 44.0), handF: Offset(5.0, 44.0),
    footN: Offset(60.0, 151.0), footF: Offset(58.0, 151.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 90.0,
  );
  static const _SidePose caB = _SidePose(
    hip: Offset(62.0, 72.0), torso: 180.0,
    handN: Offset(5.0, 44.0), handF: Offset(5.0, 44.0),
    footN: Offset(60.0, 143.0), footF: Offset(58.0, 143.0),
    rel: true, kneeN: -1, kneeF: -1, elbowN: 1, elbowF: 1, tilt: 0.0, footAngle: 40.0,
  );
  static const _SidePose esA = _SidePose(
    hip: Offset(69.9, 119.2), torso: 113.6,
    handN: Offset(104.8, 148.0), handF: Offset(104.8, 148.0),
    footN: Offset(86.0, 136.0), footF: Offset(10.0, 146.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: -30.0, footAngle: 90.0,
  );
  static const _SidePose esB = _SidePose(
    hip: Offset(69.9, 119.2), torso: 113.6,
    handN: Offset(104.8, 148.0), handF: Offset(104.8, 148.0),
    footN: Offset(10.0, 146.0), footF: Offset(86.0, 136.0),
    rel: false, kneeN: 1, kneeF: 1, elbowN: 1, elbowF: 1, tilt: -30.0, footAngle: 90.0,
  );

  // Poses de frente
  static const _FrontPose latA = _FrontPose(
    hipY: 80,
    handL: Offset(49, 84), handR: Offset(81, 84),
    footL: Offset(60, 151), footR: Offset(70, 151),
  );
  static const _FrontPose latB = _FrontPose(
    hipY: 80,
    handL: Offset(10, 44), handR: Offset(120, 44),
    footL: Offset(60, 151), footR: Offset(70, 151),
  );
  static const _FrontPose jjA = _FrontPose(
    hipY: 80,
    handL: Offset(48, 84), handR: Offset(82, 84),
    footL: Offset(60, 151), footR: Offset(70, 151),
  );
  static const _FrontPose jjB = _FrontPose(
    hipY: 72,
    handL: Offset(43, -6), handR: Offset(87, -6),
    footL: Offset(38, 143), footR: Offset(92, 143),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Ejercicios
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, _Spec> _specs = <String, _Spec>{
  'ex-1': _SideSpec(a: _P.bA, b: _P.bB, period: 2.6, ratio: 0.42, fit: _benchFit, hlArms: true, prop: _Prop.bench, ground: 146),
  'ex-2': _SideSpec(a: _P.sqA, b: _P.sqB, period: 2.8, ratio: 0.5, hlLegs: true, prop: _Prop.rack),
  'ex-3': _SideSpec(a: _P.prA, b: _P.prB, period: 2.6, hlArms: true, prop: _Prop.plate9),
  'ex-4': _SideSpec(a: _P.dlA, b: _P.dlB, period: 3.0, ratio: 0.5, hlLegs: true, hlCore: true, prop: _Prop.plate11),
  'ex-5': _SideSpec(a: _P.puA, b: _P.puB, period: 2.8, hlArms: true, prop: _Prop.pullBar, ground: -1),
  'ex-6': _SideSpec(a: _P.cuA, b: _P.cuB, period: 2.4, ratio: 0.4, curve: Curves.fastOutSlowIn, hlArms: true, prop: _Prop.dumbbellH),
  'ex-7': _SideSpec(a: _P.diA, b: _P.diB, period: 2.2, fit: _wide, hlArms: true, prop: _Prop.dipBench, ground: 120),
  'ex-8': _SideSpec(a: _P.fxA, b: _P.fxB, period: 2.2, fit: _wide, hlArms: true, ground: 150),
  'ex-9': _SideSpec(a: _P.znA, b: _P.znB, period: 2.8, ratio: 0.5, hlLegs: true, prop: _Prop.dumbbellV),
  'ex-10': _SideSpec(a: _P.reA, b: _P.reB, period: 2.4, hlArms: true, prop: _Prop.plate8),
  'ex-11': _FrontSpec(a: _P.latA, b: _P.latB, period: 2.8, ratio: 0.4, dumbbells: true, hlArms: true),
  'ex-12': _SideSpec(a: _P.trA, b: _P.trB, period: 2.6, hlArms: true, prop: _Prop.dumbbellV),
  'ex-13': _SideSpec(a: _P.abA, b: _P.abB, period: 2.2, fit: _wide, hlCore: true, prop: _Prop.mat, ground: 152),
  'ex-14': _SideSpec(a: _P.plA, b: _P.plB, period: 3.4, ratio: 0.5, fit: _wide, hlCore: true, ground: 152),
  'ex-15': _SideSpec(a: _P.pnA, b: _P.pnB, period: 2.6, fit: _wide, hlLegs: true, prop: _Prop.mat, ground: 152),
  'ex-16': _SideSpec(a: _P.caA, b: _P.caB, period: 1.8, ratio: 0.4, hlLegs: true),
  'ex-17': _SideSpec(a: _P.esA, b: _P.esB, period: 0.9, ratio: 0.5, curve: Curves.linear, fit: _wide, hlCore: true, ground: 150),
  'ex-18': _FrontSpec(a: _P.jjA, b: _P.jjB, period: 1.0, ratio: 0.5, hlArms: true, hlLegs: true),
};

/// Para ejercicios sin animación propia: una figura de pie.
const _Spec _fallback = _SideSpec(a: _P.caA, b: _P.caA, period: 3.0);