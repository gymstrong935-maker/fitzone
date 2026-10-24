import 'package:flutter/material.dart';

import '../../core/services/app_services.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/backend_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import 'admin_controller.dart';
import '../assistant/assistant_controller.dart';
import '../assistant/assistant_screen.dart';
import 'screens/admin_coach_changes_screen.dart';
import 'screens/admin_coaches_screen.dart';
import 'screens/admin_expirations_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_payments_screen.dart';
import 'screens/admin_plans_screen.dart';
import 'screens/admin_support_screen.dart';
import 'screens/admin_users_screen.dart';
import 'widgets/admin_widgets.dart';
import 'screens/admin_announcements_screen.dart';
import 'screens/admin_appointments_screen.dart';
import 'screens/admin_groups_screen.dart';

enum AdminSection {
  dashboard('Panel', Icons.space_dashboard_outlined),
  payments('Pagos', Icons.payments_outlined),
  coachChanges('Cambios de entrenador', Icons.swap_horiz_rounded),
  expirations('Vencimientos', Icons.event_busy_outlined),
  users('Usuarios', Icons.people_alt_outlined),
  coaches('Entrenadores', Icons.fitness_center_rounded),
  plans('Planes', Icons.sell_outlined),
  groups('Grupos', Icons.groups_2_outlined),
  appointments('Citas', Icons.event_available_outlined),
  support('Soporte', Icons.support_agent_rounded),
  announcements('Anuncios', Icons.campaign_outlined),
  assistant('Asistente', Icons.smart_toy_outlined);

  const AdminSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Secciones que van en la barra inferior del celular (el resto, en "Más").
const List<AdminSection> _mobileMain = <AdminSection>[
  AdminSection.dashboard,
  AdminSection.payments,
  AdminSection.users,
  AdminSection.support,
];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.user, required this.onLogout});

  final BackendUser user;
  final VoidCallback onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final AdminService _service = AppServices.instance.admin;
  late final AdminController _controller = AdminController(_service);

  AdminSection _section = AdminSection.dashboard;

  /// Chat con el asistente (el equipo de soporte también puede usarlo).
  late final AssistantController _assistant = AssistantController(
    service: AppServices.instance.chat,
    userName: widget.user.nombre,
    welcome: '¡Hola! Soy el asistente de FitZone para el equipo. Puedo darte el '
        'panorama del negocio, los pagos y cambios por validar, los planes por '
        'vencer y buscar a un usuario por nombre o correo.',
  );

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _assistant.dispose();
    super.dispose();
  }

  void _go(AdminSection section) => setState(() => _section = section);

  Future<void> _logout() async {
    final bool ok = await adminConfirm(
      context,
      title: '¿Cerrar sesión?',
      message: 'Saldrás del panel administrativo.',
      confirmLabel: 'Cerrar sesión',
    );
    if (ok) widget.onLogout();
  }

  int _badge(AdminSection s) {
    if (s == AdminSection.payments) return _controller.pendingPayments;
    if (s == AdminSection.support) return _controller.openTickets;
    if (s == AdminSection.users) return _controller.pendingAccounts;
    if (s == AdminSection.coachChanges) return _controller.pendingCoachChanges;
    if (s == AdminSection.expirations) return _controller.expiringSoon;
    return 0;
  }

  Widget _content() {
    final Widget page;
    switch (_section) {
      case AdminSection.dashboard:
        page = AdminDashboardScreen(controller: _controller, service: _service, onNavigate: _go);
      case AdminSection.payments:
        page = AdminPaymentsScreen(service: _service, controller: _controller);
      case AdminSection.coachChanges:
        page = AdminCoachChangesScreen(service: _service, controller: _controller);
      case AdminSection.expirations:
        page = AdminExpirationsScreen(service: _service, controller: _controller);
      case AdminSection.users:
        page = AdminUsersScreen(service: _service, controller: _controller);
      case AdminSection.coaches:
        page = AdminCoachesScreen(service: _service);
      case AdminSection.plans:
        page = AdminPlansScreen(service: _service);
      case AdminSection.support:
        page = AdminSupportScreen(service: _service, controller: _controller);
      case AdminSection.groups:
        page = AdminGroupsScreen(service: _service);
      case AdminSection.appointments:
        page = AdminAppointmentsScreen(service: _service);
      case AdminSection.announcements:
        page = AdminAnnouncementsScreen(service: _service);
      case AdminSection.assistant:
        page = AssistantScreen(
          controller: _assistant,
          staff: true,
          onBack: () => _go(AdminSection.dashboard),
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(key: ValueKey<AdminSection>(_section), child: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AmbientBackground()),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final bool wide = c.maxWidth >= 860;
              return ListenableBuilder(
                listenable: _controller,
                builder: (BuildContext context, Widget? _) {
                  if (wide) {
                    return Row(
                      children: <Widget>[
                        _Sidebar(
                          user: widget.user,
                          section: _section,
                          badge: _badge,
                          onSelect: _go,
                          onLogout: _logout,
                        ),
                        Expanded(child: _content()),
                      ],
                    );
                  }

                  return SafeArea(
                    child: Column(
                      children: <Widget>[
                        _MobileTopBar(section: _section),
                        Expanded(child: _content()),
                        _MobileBottomNav(
                          section: _section,
                          badge: _badge,
                          onSelect: _go,
                          onMore: () => _showMore(context),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const Positioned(top: 0, left: 0, right: 0, child: ShimmerTopBar()),
        ],
      ),
    );
  }

  void _showMore(BuildContext context) {
    showAdminSheet<void>(
      context,
      (BuildContext ctx) => AdminSheet(
        title: 'Más secciones',
        subtitle: widget.user.email,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final AdminSection s in AdminSection.values)
              if (!_mobileMain.contains(s))
                _MoreItem(
                  section: s,
                  selected: s == _section,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _go(s);
                  },
                ),
            const SizedBox(height: 12),
            AdminButton(
              label: 'Cerrar sesión',
              icon: Icons.logout_rounded,
              kind: AdminButtonKind.danger,
              onTap: () {
                Navigator.of(ctx).pop();
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Navegación
// ═══════════════════════════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.user,
    required this.section,
    required this.badge,
    required this.onSelect,
    required this.onLogout,
  });

  final BackendUser user;
  final AdminSection section;
  final int Function(AdminSection) badge;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: AppColors.glass(0.8),
        border: Border(right: BorderSide(color: AppColors.whiteA(0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[AppColors.cyanA(0.30), AppColors.tealA(0.20)],
                        ),
                        border: Border.all(color: AppColors.cyanA(0.5)),
                      ),
                      child: Text(
                        'FZ',
                        style: AppText.display(size: 14, weight: FontWeight.w700, color: AppColors.cyanText),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('FitZone', style: AppText.display(size: 17, weight: FontWeight.w700, height: 1.2)),
                        Text('Administración', style: AppText.body(size: 12, color: AppColors.whiteA(0.45))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    for (final AdminSection s in AdminSection.values)
                      _SidebarItem(
                        section: s,
                        selected: s == section,
                        badge: badge(s),
                        onTap: () => onSelect(s),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.whiteA(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.whiteA(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      user.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 13.5, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 12, color: AppColors.whiteA(0.45)),
                    ),
                    const SizedBox(height: 10),
                    AdminButton(
                      label: 'Cerrar sesión',
                      icon: Icons.logout_rounded,
                      compact: true,
                      onTap: onLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final AdminSection section;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected ? AppColors.cyanA(0.14) : Colors.transparent,
              border: Border.all(color: selected ? AppColors.cyanA(0.30) : Colors.transparent),
            ),
            child: Row(
              children: <Widget>[
                Icon(section.icon, size: 19, color: selected ? AppColors.cyanText : AppColors.whiteA(0.55)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.label,
                    style: AppText.body(
                      size: 14,
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.cyanText : AppColors.whiteA(0.75),
                    ),
                  ),
                ),
                if (badge > 0) _Badge(count: badge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.redStrong, borderRadius: BorderRadius.circular(10)),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: AppText.body(size: 11, weight: FontWeight.w700, color: Colors.white, height: 1),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.section});

  final AdminSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      alignment: Alignment.centerLeft,
      child: Row(
        children: <Widget>[
          Icon(section.icon, size: 18, color: AppColors.cyanText),
          const SizedBox(width: 10),
          Text(
            'Admin · ${section.label}',
            style: AppText.display(size: 15, weight: FontWeight.w700, color: AppColors.whiteA(0.85)),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.section,
    required this.badge,
    required this.onSelect,
    required this.onMore,
  });

  final AdminSection section;
  final int Function(AdminSection) badge;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final bool moreSelected = !_mobileMain.contains(section);

    Widget item(IconData icon, String label, bool selected, int count, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Icon(icon, size: 22, color: selected ? AppColors.cyanText : AppColors.whiteA(0.50)),
                    if (count > 0)
                      Positioned(top: -6, right: -12, child: _Badge(count: count)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w600,
                    color: selected ? AppColors.cyanText : AppColors.whiteA(0.50),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass(0.95),
        border: Border(top: BorderSide(color: AppColors.whiteA(0.08))),
      ),
      child: Row(
        children: <Widget>[
          for (final AdminSection s in _mobileMain)
            item(s.icon, s.label, s == section, badge(s), () => onSelect(s)),
          item(Icons.menu_rounded, 'Más', moreSelected, 0, onMore),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({required this.section, required this.selected, required this.onTap});

  final AdminSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyanA(0.12) : AppColors.whiteA(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.cyanA(0.30) : AppColors.whiteA(0.09)),
        ),
        child: Row(
          children: <Widget>[
            Icon(section.icon, size: 20, color: selected ? AppColors.cyanText : AppColors.whiteA(0.65)),
            const SizedBox(width: 12),
            Text(
              section.label,
              style: AppText.body(size: 15, weight: FontWeight.w600, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
