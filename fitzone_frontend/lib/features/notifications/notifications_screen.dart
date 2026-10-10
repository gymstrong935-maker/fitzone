import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/notifications_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/sub_screen_frame.dart';
import 'notifications_controller.dart';

/// Pantalla "Notificaciones": lista real del servidor.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final NotificationsController controller;
  final VoidCallback onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Al abrir, trae lo más reciente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final int unread = widget.controller.unreadCount;

        return SubScreenFrame(
          title: 'Notificaciones',
          subtitle: unread == 0 ? 'Estás al día' : '$unread sin leer',
          onBack: widget.onBack,
          child: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    final NotificationsController c = widget.controller;

    if (!c.loaded && c.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (c.error != null) ...<Widget>[
          ErrorBox(c.error!),
          const SizedBox(height: 12),
        ],
        if (c.items.isEmpty && c.error == null)
          _buildEmpty()
        else ...<Widget>[
          _buildToolbar(c),
          const SizedBox(height: 12),
          for (int i = 0; i < c.items.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            FadeSlideIn(
              key: ValueKey<String>(c.items[i].id),
              delay: Duration(milliseconds: math.min(i, 8) * 40),
              duration: const Duration(milliseconds: 350),
              offsetY: 8,
              child: _NotificationCard(
                notification: c.items[i],
                onTap: () => c.markRead(c.items[i].id),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildToolbar(NotificationsController c) {
    final int unread = c.unreadCount;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '${c.items.length} ${c.items.length == 1 ? 'notificación' : 'notificaciones'}',
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.40),
              height: 1.333,
            ),
          ),
        ),
        _PillButton(
          icon: Icons.refresh_rounded,
          label: c.loading ? 'Actualizando...' : 'Actualizar',
          onTap: c.loading ? null : () => c.refresh(),
        ),
        if (unread > 0) ...<Widget>[
          const SizedBox(width: 8),
          _PillButton(
            icon: Icons.done_all_rounded,
            label: 'Marcar todas',
            highlighted: true,
            onTap: c.markAllRead,
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
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
            child: const Text('🔔', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes notificaciones',
            style: AppText.display(
              size: 16,
              weight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aquí verás avisos sobre tu plan, pagos y entrenamientos.',
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

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color color = onTap == null
        ? AppColors.whiteA(0.35)
        : (highlighted ? AppColors.cyan : AppColors.whiteA(0.70));

    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.cyanA(0.12) : AppColors.whiteA(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlighted ? AppColors.cyanA(0.30) : AppColors.whiteA(0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: color,
                  height: 1.333,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _teal400 = Color(0xFF2DD4BF);
  static const Color _amber400 = Color(0xFFFBBF24);
  static const Color _violet400 = Color(0xFFA78BFA);

  ({IconData icon, Color color}) get _style {
    switch (notification.type) {
      case NotificationType.payment:
        return (icon: Icons.payments_outlined, color: _cyan400);
      case NotificationType.reminder:
        return (icon: Icons.alarm_rounded, color: _amber400);
      case NotificationType.workout:
        return (icon: Icons.fitness_center_rounded, color: _teal400);
      case NotificationType.system:
        return (icon: Icons.campaign_outlined, color: _violet400);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool unread = !notification.read;
    final Color accent = _style.color;

    return Semantics(
      button: true,
      label: notification.message,
      child: MouseRegion(
        cursor: unread ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: unread ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unread ? AppColors.cyanA(0.06) : AppColors.whiteA(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unread ? AppColors.cyanA(0.25) : AppColors.whiteA(0.08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withAlpha(36),
                  ),
                  child: Icon(_style.icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        notification.message,
                        style: AppText.body(
                          size: 14,
                          weight: unread ? FontWeight.w600 : FontWeight.w400,
                          color: unread ? Colors.white : AppColors.whiteA(0.65),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRelativeTime(notification.sentAt),
                        style: AppText.body(
                          size: 12,
                          color: AppColors.whiteA(0.40),
                          height: 1.333,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...<Widget>[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}