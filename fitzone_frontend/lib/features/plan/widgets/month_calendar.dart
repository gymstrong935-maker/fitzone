import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

const List<String> _monthNames = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const List<String> _weekdayHeads = <String>[
  'Lu',
  'Ma',
  'Mi',
  'Ju',
  'Vi',
  'Sá',
  'Do',
];

/// Calendario mensual: flechas para cambiar de mes y selección de un día.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  /// Primer día del mes que se está viendo.
  late DateTime _visible;

  @override
  void initState() {
    super.initState();
    _visible = DateTime(widget.selected.year, widget.selected.month);
  }

  void _shift(int delta) {
    setState(() => _visible = DateTime(_visible.year, _visible.month + delta));
  }

  void _select(DateTime date) {
    widget.onSelect(date);
    // Si tocan un día de otro mes (los grises), el calendario salta a ese mes.
    if (date.month != _visible.month || date.year != _visible.year) {
      setState(() => _visible = DateTime(date.year, date.month));
    }
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Semanas del mes visible (de lunes a domingo), incluyendo los días de
  /// los meses vecinos que completan la primera y la última fila.
  List<List<DateTime>> _weeks() {
    final DateTime first = DateTime(_visible.year, _visible.month, 1);
    final int leading = first.weekday - 1; // lunes = 0
    final int daysInMonth = DateTime(_visible.year, _visible.month + 1, 0).day;
    final int weekCount = ((leading + daysInMonth) / 7).ceil();

    return <List<DateTime>>[
      for (int w = 0; w < weekCount; w++)
        <DateTime>[
          for (int d = 0; d < 7; d++)
            DateTime(first.year, first.month, 1 - leading + w * 7 + d),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Título + flechas ──
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Text(
                    '${_monthNames[_visible.month - 1]} ${_visible.year}',
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.43,
                    ),
                  ),
                  Positioned(
                    left: 4,
                    child: _NavButton(
                      icon: Icons.chevron_left_rounded,
                      label: 'Mes anterior',
                      onTap: () => _shift(-1),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    child: _NavButton(
                      icon: Icons.chevron_right_rounded,
                      label: 'Mes siguiente',
                      onTap: () => _shift(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Días de la semana ──
          Row(
            children: <Widget>[
              for (final String head in _weekdayHeads)
                Expanded(
                  child: Center(
                    child: Text(
                      head,
                      style: AppText.body(
                        size: 12,
                        color: AppColors.whiteA(0.40),
                        height: 1.333,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Semanas ──
          for (final List<DateTime> week in _weeks()) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                for (final DateTime date in week)
                  Expanded(
                    child: _DayCell(
                      date: date,
                      isSelected: _sameDay(date, widget.selected),
                      isToday: _sameDay(date, today),
                      isOutside: date.month != _visible.month,
                      onTap: () => _select(date),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: AnimatedOpacity(
                opacity: _hover ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 150),
                child: Icon(widget.icon, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isOutside,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;
  final VoidCallback onTap;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  static const Color _cyan400 = Color(0xFF22D3EE);

  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.isSelected;

    final Color textColor = selected
        ? Colors.black
        : widget.isToday
            ? _cyan400
            : widget.isOutside
                ? AppColors.whiteA(0.20)
                : AppColors.whiteA(0.80);

    return Semantics(
      button: true,
      selected: selected,
      label: '${widget.date.day} de ${_monthNames[widget.date.month - 1]}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[AppColors.cyan, AppColors.teal],
                    )
                  : null,
              color: selected
                  ? null
                  : _hover
                      ? AppColors.whiteA(0.10)
                      : Colors.transparent,
            ),
            child: Text(
              '${widget.date.day}',
              style: AppText.body(
                size: 14,
                weight: widget.isToday && !selected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: textColor,
                height: 1.43,
              ),
            ),
          ),
        ),
      ),
    );
  }
}