import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../onboarding/data/goals_data.dart';
import '../../onboarding/data/trainers_data.dart';
import '../../onboarding/models/goal.dart';
import '../../onboarding/models/trainer.dart';
import '../../onboarding/widgets/fz_field_frame.dart';
import '../../onboarding/widgets/fz_label.dart';

// ═══════════════════════════════════════════════════════════════════════════
// API pública
// ═══════════════════════════════════════════════════════════════════════════

/// Hoja para editar el nombre. Devuelve el nuevo nombre o `null` si se cierra.
Future<String?> showEditProfileSheet(
  BuildContext context, {
  required String name,
  required String email,
}) {
  return _showSheet<String>(
    context,
    (BuildContext ctx) => _EditProfileSheet(name: name, email: email),
  );
}

/// Hoja para elegir el objetivo. Devuelve el objetivo elegido o `null`.
Future<Goal?> showGoalSheet(BuildContext context, {Goal? current}) {
  return _showSheet<Goal>(
    context,
    (BuildContext ctx) => _SheetFrame(
      title: 'Cambiar Objetivo',
      subtitle: 'Selecciona tu objetivo principal',
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: kGoals.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final GoalOption option = kGoals[index];
          return _OptionRow(
            selected: option.id == current,
            title: option.title,
            subtitle: option.description,
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[option.from, option.to],
                ),
              ),
              child: Text(option.icon, style: const TextStyle(fontSize: 20)),
            ),
            onTap: () => Navigator.of(context).pop(option.id),
          );
        },
      ),
    ),
  );
}

/// Hoja para elegir entrenador. Devuelve el entrenador elegido o `null`.
Future<Trainer?> showTrainerSheet(BuildContext context, {Trainer? current}) {
  return _showSheet<Trainer>(
    context,
    (BuildContext ctx) => _SheetFrame(
      title: 'Cambiar Entrenador',
      subtitle: 'Elige al profesional que mejor se adapte a ti',
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: kTrainers.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final Trainer trainer = kTrainers[index];
          return _OptionRow(
            selected: trainer.id == current?.id,
            title: trainer.name,
            subtitle: trainer.specialty,
            trailingText: '\$${trainer.price}${trainer.priceDescription}',
            leading: _TrainerPhoto(url: trainer.photo),
            onTap: () => Navigator.of(context).pop(trainer),
          );
        },
      ),
    ),
  );
}

/// Cuadro de confirmación de "Cerrar Sesión". Devuelve `true` si confirma.
Future<bool?> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0xB3000000),
    builder: (BuildContext ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.whiteA(0.10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '¿Cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: AppText.display(
                    size: 20,
                    weight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Volverás a la pantalla de selección de plan.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 14,
                    color: AppColors.whiteA(0.60),
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _DialogButton(
                        label: 'Cancelar',
                        background: AppColors.whiteA(0.08),
                        border: AppColors.whiteA(0.12),
                        textColor: Colors.white,
                        onTap: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        label: 'Cerrar sesión',
                        background: const Color.fromRGBO(239, 68, 68, 0.12),
                        border: const Color.fromRGBO(239, 68, 68, 0.30),
                        textColor: const Color(0xFFF87171),
                        onTap: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas internas
// ═══════════════════════════════════════════════════════════════════════════

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000),
    constraints: const BoxConstraints(maxWidth: 512),
    builder: builder,
  );
}

/// Marco común de las hojas: asa, título, subtítulo y contenido.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFA0A0A0A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.whiteA(0.10))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.whiteA(0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppText.body(
                  size: 14,
                  color: AppColors.whiteA(0.50),
                  height: 1.43,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Fila seleccionable de una hoja (objetivo o entrenador).
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.trailingText,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final Widget leading;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? AppColors.cyanA(0.09) : AppColors.whiteA(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.cyan : AppColors.whiteA(0.10),
                width: 1.5,
              ),
            ),
            child: Row(
              children: <Widget>[
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.43,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppText.body(
                          size: 12,
                          color: AppColors.whiteA(0.55),
                          height: 1.333,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingText != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Text(
                    trailingText!,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF2DD4BF),
                    ),
                  ),
                ],
                if (selected) ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Color(0xFF0A0A0A),
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

class _TrainerPhoto extends StatelessWidget {
  const _TrainerPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? progress,
          ) {
            if (progress == null) return child;
            return ColoredBox(color: AppColors.whiteA(0.08));
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return ColoredBox(
              color: AppColors.whiteA(0.08),
              child: Icon(
                Icons.person_outline_rounded,
                size: 24,
                color: AppColors.whiteA(0.4),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.border,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color border;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: textColor,
            height: 1.43,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Hoja: editar perfil
// ═══════════════════════════════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.name, required this.email});

  final String name;
  final String email;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  bool get _valid => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name)
      ..addListener(_rebuild);
    _focus = FocusNode()..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _focus.removeListener(_rebuild);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Editar Perfil',
      subtitle: 'Actualiza tu nombre',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const FzLabel('Nombre'),
            const SizedBox(height: 6),
            FzFieldFrame(
              focused: _focus.hasFocus,
              height: 44,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(40),
                ],
                onSubmitted: (_) => _save(),
                cursorColor: Colors.white,
                style: AppText.body(size: 15, color: Colors.white),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Tu nombre',
                  hintStyle: AppText.body(
                    size: 15,
                    color: AppColors.whiteA(0.30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const FzLabel('Correo electrónico'),
            const SizedBox(height: 6),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.whiteA(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.whiteA(0.08)),
              ),
              child: Text(
                widget.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 15, color: AppColors.whiteA(0.45)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _valid ? _save : null,
              child: AnimatedOpacity(
                opacity: _valid ? 1 : 0.4,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: <Color>[AppColors.cyan, AppColors.teal],
                    ),
                  ),
                  child: Text(
                    'Guardar cambios',
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w600,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}