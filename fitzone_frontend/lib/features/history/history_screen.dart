import 'package:flutter/material.dart';

import '../../core/services/workouts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/sub_screen_frame.dart';
import 'data/history_data.dart';
import 'workouts_controller.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _fatigueLabel(String v) {
  switch (v) {
    case 'none':
      return '😊 Sin fatiga';
    case 'moderate':
      return '😌 Fatiga moderada';
    case 'fatigued':
      return '😓 Fatigado';
    case 'high':
      return '😰 Fatiga alta';
    case 'veryHigh':
      return '😵 Fatiga muy alta';
    default:
      return '—';
  }
}

String _sorenessLabel(String v) {
  switch (v) {
    case 'none':
      return '💪 Sin agujetas';
    case 'light':
      return '😊 Agujetas ligeras';
    case 'moderate':
      return '😅 Agujetas moderadas';
    case 'intense':
      return '😣 Agujetas intensas';
    default:
      return '—';
  }
}

/// Pantalla "Historial": entrenamientos reales guardados en el servidor.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final WorkoutsController controller;
  final VoidCallback onBack;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color _orange500 = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    // Al abrir, trae lo más reciente y reenvía lo pendiente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.refresh();
      widget.controller.flushPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final WorkoutsController c = widget.controller;
        final List<SavedWorkout> sessions = c.sessions;

        return SubScreenFrame(
          title: 'Historial',
          subtitle: sessions.isEmpty
              ? 'Entrenamientos realizados'
              : '${sessions.length} ${sessions.length == 1 ? 'entrenamiento' : 'entrenamientos'}',
          onBack: widget.onBack,
          child: _buildBody(c, sessions),
        );
      },
    );
  }

  Widget _buildBody(WorkoutsController c, List<SavedWorkout> sessions) {
    if (!c.loaded && c.loading && sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
      );
    }

    final int totalMinutes =
        sessions.fold<int>(0, (int s, SavedWorkout w) => s + w.durationMinutes);
    final int totalCalories =
        sessions.fold<int>(0, (int s, SavedWorkout w) => s + w.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (c.error != null) ...<Widget>[
          ErrorBox(c.error!),
          const SizedBox(height: 12),
        ],
        if (c.pendingCount > 0) ...<Widget>[
          _PendingNotice(count: c.pendingCount),
          const SizedBox(height: 12),
        ],

        // ── Resumen ──
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryTile(
                label: 'Esta semana',
                value: '${c.sessionsThisWeek}',
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: 'Total min',
                value: '$totalMinutes',
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: 'Total kcal',
                value: '$totalCalories',
                color: _orange500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (sessions.isEmpty)
          const _EmptyState()
        else
          for (int i = 0; i < sessions.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            FadeSlideIn(
              key: ValueKey<String>(
                sessions[i].id.isEmpty ? sessions[i].clientId : sessions[i].id,
              ),
              delay: Duration(milliseconds: (i < 8 ? i : 8) * 50),
              duration: const Duration(milliseconds: 400),
              offsetY: 8,
              child: _WorkoutCard(workout: sessions[i]),
            ),
          ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              color: color,
              height: 1.556,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.40),
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  const _PendingNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(251, 191, 36, 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(251, 191, 36, 0.25)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFFBBF24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? '1 entrenamiento está esperando para guardarse en el servidor. Se enviará solo.'
                  : '$count entrenamientos están esperando para guardarse en el servidor. Se enviarán solos.',
              style: AppText.body(
                size: 12,
                color: const Color(0xFFFBBF24),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyanA(0.10),
              border: Border.all(color: AppColors.cyanA(0.20)),
            ),
            child: const Text('🏋️', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no has completado entrenamientos',
            textAlign: TextAlign.center,
            style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando termines uno desde Inicio aparecerá aquí.',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 13,
              color: AppColors.whiteA(0.45),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  const _WorkoutCard({required this.workout});

  final SavedWorkout workout;

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  static const Color _green400 = Color(0xFF4ADE80);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _amber400 = Color(0xFFFBBF24);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final SavedWorkout w = widget.workout;
    final DateTime d = w.date.toLocal();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _expanded ? AppColors.cyanA(0.30) : AppColors.whiteA(0.09),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: w.pending
                          ? const Color.fromRGBO(251, 191, 36, 0.15)
                          : const Color.fromRGBO(52, 211, 153, 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      w.pending ? Icons.schedule_rounded : Icons.check_rounded,
                      size: 18,
                      color: w.pending ? _amber400 : _green400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          w.title,
                          style: AppText.display(
                            size: 14,
                            weight: FontWeight.w700,
                            height: 1.43,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatWorkoutDate(d)} · ${_two(d.hour)}:${_two(d.minute)}',
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.40),
                            height: 1.333,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${w.calories} kcal',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: _orange400,
                          height: 1.333,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.history_rounded,
                            size: 12,
                            color: AppColors.whiteA(0.40),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${w.durationMinutes} min',
                            style: AppText.body(
                              size: 12,
                              color: AppColors.whiteA(0.40),
                              height: 1.333,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _expanded ? _buildDetails(w) : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(SavedWorkout w) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(height: 1, color: AppColors.whiteA(0.07)),
          const SizedBox(height: 12),
          for (int i = 0; i < w.exercises.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    w.exercises[i].name,
                    style: AppText.body(
                      size: 13,
                      color: AppColors.whiteA(0.80),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${w.exercises[i].sets} × ${w.exercises[i].reps}',
                  style: AppText.body(
                    size: 13,
                    color: AppColors.whiteA(0.50),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Chip(text: _fatigueLabel(w.fatigue)),
              _Chip(text: _sorenessLabel(w.soreness)),
              if (w.restingHeartRate != null)
                _Chip(text: '❤️ ${w.restingHeartRate} BPM en reposo'),
              if (w.pending) const _Chip(text: '⏳ Pendiente de enviar'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.whiteA(0.10)),
      ),
      child: Text(
        text,
        style: AppText.body(size: 12, color: AppColors.whiteA(0.65), height: 1.333),
      ),
    );
  }
}