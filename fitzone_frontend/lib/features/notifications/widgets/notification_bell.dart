import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Campana con globito rojo de notificaciones sin leer.
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.unread,
    required this.onTap,
  });

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unread > 0
          ? 'Notificaciones, $unread sin leer'
          : 'Notificaciones',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.whiteA(0.10),
                    border: Border.all(color: AppColors.whiteA(0.15)),
                  ),
                  child: Icon(
                    unread > 0
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: AppText.body(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}