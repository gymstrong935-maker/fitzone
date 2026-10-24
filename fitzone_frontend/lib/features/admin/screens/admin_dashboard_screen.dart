import 'package:flutter/material.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/error_box.dart';
import '../../../core/widgets/pulsing_dots.dart';
import '../admin_controller.dart';
import '../admin_shell.dart';
import '../widgets/admin_widgets.dart';

const List<String> _monthLabels = <String>[
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

String _compactCop(num v) {
  if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '\$${(v / 1000).round()}k';
  return '\$${v.round()}';
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.service,
    required this.onNavigate,
  });

  final AdminController controller;
  final AdminService service;
  final ValueChanged<AdminSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final Map<String, dynamic> stats = controller.stats;

        return AdminPage(
          title: 'Panel',
          subtitle: 'Resumen general de FitZone',
          actions: <Widget>[
            AdminButton(
              label: 'Actualizar',
              icon: Icons.refresh_rounded,
              onTap: controller.loading ? null : () => controller.refresh(),
            ),
            AdminButton(
              label: 'Revisar vencimientos',
              icon: Icons.event_busy_outlined,
              onTap: () => onNavigate(AdminSection.expirations),
            ),
          ],
          child: stats.isEmpty
              ? (controller.error != null
                  ? ErrorBox(controller.error!)
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
                    ))
              : _buildContent(stats),
        );
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> stats) {
    final Map<String, dynamic> users = asMap(stats['usuarios']);
    final Map<String, dynamic> subs = asMap(stats['suscripciones']);
    final Map<String, dynamic> income = asMap(stats['ingresos']);
    final int pending = asNum(subs['pendientes']).toInt();
    final int tickets = asNum(stats['ticketsAbiertos']).toInt();

    final List<_Tile> tiles = <_Tile>[
      _Tile(
        icon: Icons.people_alt_outlined,
        color: AppColors.cyan,
        label: 'Usuarios',
        value: '${asNum(users['total']).toInt()}',
        sub: '+${asNum(users['nuevosSemana']).toInt()} esta semana',
        onTap: () => onNavigate(AdminSection.users),
      ),
        _Tile(
        icon: Icons.how_to_reg_outlined,
        color: AppColors.amber,
        label: 'Cuentas por aprobar',
        value: '${asNum(users['pendientes']).toInt()}',
        sub: asNum(users['pendientes']) == 0 ? 'todo al día' : 'esperan tu aprobación',
        alert: asNum(users['pendientes']) > 0,
        onTap: () => onNavigate(AdminSection.users),
      ),
      _Tile(
        icon: Icons.verified_outlined,
        color: AppColors.green,
        label: 'Suscripciones activas',
        value: '${asNum(subs['activas']).toInt()}',
        sub: 'planes vigentes',
        onTap: () => onNavigate(AdminSection.payments),
      ),
      _Tile(
        icon: Icons.hourglass_top_rounded,
        color: AppColors.amber,
        label: 'Pagos pendientes',
        value: '$pending',
        sub: pending == 0 ? 'todo al día' : 'esperan aprobación',
        alert: pending > 0,
        onTap: () => onNavigate(AdminSection.payments),
      ),
      _Tile(
        icon: Icons.swap_horiz_rounded,
        color: AppColors.violet,
        label: 'Cambios de entrenador',
        value: '${asNum(stats['cambiosEntrenadorPendientes']).toInt()}',
        sub: asNum(stats['cambiosEntrenadorPendientes']) == 0
            ? 'todo al día'
            : 'esperan tu validación',
        alert: asNum(stats['cambiosEntrenadorPendientes']) > 0,
        onTap: () => onNavigate(AdminSection.coachChanges),
      ),
      _Tile(
        icon: Icons.event_busy_outlined,
        color: AppColors.orange,
        label: 'Por vencer (7 días)',
        value: '${asNum(subs['porVencer']).toInt()}',
        sub: asNum(subs['porVencer']) == 0 ? 'nadie por vencer' : 'planes que terminan pronto',
        alert: asNum(subs['porVencer']) > 0,
        onTap: () => onNavigate(AdminSection.expirations),
      ),
      _Tile(
        icon: Icons.payments_outlined,
        color: AppColors.teal400,
        label: 'Ingresos totales',
        value: formatCop(asNum(income['total'])),
        sub: 'pagos aprobados',
      ),
      _Tile(
        icon: Icons.fitness_center_rounded,
        color: AppColors.violet,
        label: 'Entrenadores',
        value: '${asNum(stats['entrenadores']).toInt()}',
        sub: 'en la plataforma',
        onTap: () => onNavigate(AdminSection.coaches),
      ),
      _Tile(
        icon: Icons.event_available_outlined,
        color: AppColors.blue,
        label: 'Citas próximas',
        value: '${asNum(stats['citasProximas']).toInt()}',
        sub: 'confirmadas',
        onTap: () => onNavigate(AdminSection.appointments),
      ),
      _Tile(
        icon: Icons.support_agent_rounded,
        color: AppColors.pink,
        label: 'Soporte abierto',
        value: '$tickets',
        sub: tickets == 0 ? 'sin pendientes' : 'solicitudes sin cerrar',
        alert: tickets > 0,
        onTap: () => onNavigate(AdminSection.support),
      ),
      _Tile(
        icon: Icons.local_fire_department_outlined,
        color: AppColors.orange,
        label: 'Entrenamientos',
        value: '${asNum(stats['entrenamientosSemana']).toInt()}',
        sub: 'últimos 7 días',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int columns = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 3 : 2);
        const double gap = 12;
        final double tileWidth = (c.maxWidth - gap * (columns - 1)) / columns;
        final bool sideBySide = c.maxWidth >= 760;

        final Widget revenue = _RevenueCard(months: asList(income['mensuales']));
        final Widget plans = _PlansCard(plans: asList(stats['planes']));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: <Widget>[
                for (final _Tile t in tiles) SizedBox(width: tileWidth, child: t),
              ],
            ),
            const SizedBox(height: 16),
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: revenue),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: plans),
                ],
              )
            else ...<Widget>[revenue, const SizedBox(height: 16), plans],
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
    this.onTap,
    this.alert = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;
  final VoidCallback? onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      highlight: alert ? color.withAlpha(120) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withAlpha(36), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.display(size: 24, weight: FontWeight.w700, color: color, height: 1.2),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.ink)),
          Text(sub, style: AppText.body(size: 12, color: AppColors.whiteA(0.40), height: 1.4)),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.months});

  final List<Map<String, dynamic>> months;

  @override
  Widget build(BuildContext context) {
    num maxValue = 0;
    for (final Map<String, dynamic> m in months) {
      final num v = asNum(m['total']);
      if (v > maxValue) maxValue = v;
    }

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Ingresos de los últimos 6 meses',
            style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Pagos aprobados, en pesos',
            style: AppText.body(size: 12, color: AppColors.whiteA(0.40)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final Map<String, dynamic> m in months)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _Bar(
                        label: _monthLabels[(asNum(m['mes']).toInt() - 1).clamp(0, 11)],
                        value: asNum(m['total']),
                        fraction: maxValue <= 0 ? 0 : asNum(m['total']) / maxValue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.fraction});

  final String label;
  final num value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(
          value > 0 ? _compactCop(value) : '',
          style: AppText.body(size: 11, color: AppColors.whiteA(0.55)),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (BuildContext context, double v, Widget? _) {
            return Container(
              height: 6 + 120 * v,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                gradient: value > 0
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[AppColors.cyan, AppColors.teal],
                      )
                    : null,
                color: value > 0 ? null : AppColors.whiteA(0.08),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(label, style: AppText.body(size: 12, color: AppColors.whiteA(0.45))),
      ],
    );
  }
}

class _PlansCard extends StatelessWidget {
  const _PlansCard({required this.plans});

  final List<Map<String, dynamic>> plans;

  @override
  Widget build(BuildContext context) {
    num total = 0;
    for (final Map<String, dynamic> p in plans) {
      total += asNum(p['total']);
    }

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Suscripciones por plan',
            style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (plans.isEmpty)
            Text(
              'Todavía no hay suscripciones activas.',
              style: AppText.body(size: 13, color: AppColors.whiteA(0.45)),
            )
          else
            for (int i = 0; i < plans.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    str(plans[i]['nombre']),
                    style: AppText.body(size: 13, color: AppColors.whiteA(0.80)),
                  ),
                  Text(
                    '${asNum(plans[i]['total']).toInt()}',
                    style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total <= 0 ? 0 : (asNum(plans[i]['total']) / total).toDouble(),
                  minHeight: 6,
                  backgroundColor: AppColors.whiteA(0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
            ],
        ],
      ),
    );
  }
}