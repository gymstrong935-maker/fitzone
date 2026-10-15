import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/error_box.dart';
import '../../../core/widgets/pulsing_dots.dart';
import '../../onboarding/widgets/fz_field_frame.dart';
import '../../onboarding/widgets/fz_label.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Lectura segura de JSON
// ═══════════════════════════════════════════════════════════════════════════

String str(Object? v) => v == null ? '' : v.toString();

Map<String, dynamic> asMap(Object? v) =>
    v is Map<String, dynamic> ? v : const <String, dynamic>{};

List<Map<String, dynamic>> asList(Object? v) => v is List
    ? <Map<String, dynamic>>[
        for (final Object? e in v)
          if (e is Map<String, dynamic>) e,
      ]
    : const <Map<String, dynamic>>[];

List<String> asStrings(Object? v) =>
    v is List ? <String>[for (final Object? e in v) e.toString()] : const <String>[];

num asNum(Object? v) => v is num ? v : (num.tryParse(str(v)) ?? 0);

DateTime? asDate(Object? v) => DateTime.tryParse(str(v))?.toLocal();

const List<String> _months = <String>[
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic',
];

String shortDate(DateTime? d) =>
    d == null ? '—' : '${d.day} ${_months[d.month - 1]} ${d.year}';

String shortDateTime(DateTime? d) {
  if (d == null) return '—';
  final String h = d.hour.toString().padLeft(2, '0');
  final String m = d.minute.toString().padLeft(2, '0');
  return '${shortDate(d)} · $h:$m';
}

Color statusColor(String estado) {
  switch (estado) {
    case 'activa':
    case 'aprobado':
    case 'confirmada':
    case 'cerrado':
    case 'activo':
      return const Color(0xFF34D399);
    case 'pendiente':
    case 'abierto':
      return const Color(0xFFFBBF24);
    case 'en_proceso':
      return AppColors.cyan;
    case 'rechazada':
    case 'rechazado':
    case 'cancelada':
    case 'vencida':
    case 'suspendida':
    case 'inactiva':
      return const Color(0xFFF87171);
    default:
      return const Color(0xFFA78BFA);
  }
}

String statusLabel(String estado) {
  if (estado.isEmpty) return '—';
  final String text = estado.replaceAll('_', ' ');
  return text[0].toUpperCase() + text.substring(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// Estructura de página
// ═══════════════════════════════════════════════════════════════════════════

/// Página del panel: título, subtítulo, acciones y contenido con scroll.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: AppText.display(
                  size: 26,
                  weight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppText.body(size: 14, color: AppColors.whiteA(0.50), height: 1.5),
                ),
              ],
              if (actions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Carga datos y los muestra; mantiene lo anterior visible al recargar.
class AdminFuture<T> extends StatefulWidget {
  const AdminFuture({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  ) builder;

  @override
  State<AdminFuture<T>> createState() => _AdminFutureState<T>();
}

class _AdminFutureState<T> extends State<AdminFuture<T>> {
  T? _data;
  String? _error;
  bool _busy = true;
  bool _has = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      final T data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _has = true;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ocurrió un error inesperado.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_has) {
      if (_busy) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ErrorBox(_error ?? 'No se pudo cargar.'),
          const SizedBox(height: 12),
          AdminButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: _run),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_error != null) ...<Widget>[ErrorBox(_error!), const SizedBox(height: 12)],
        widget.builder(context, _data as T, _run),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Componentes
// ═══════════════════════════════════════════════════════════════════════════

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.highlight,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Color del borde resaltado (p. ej. pagos pendientes).
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ?? AppColors.whiteA(0.09)),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: AppText.body(size: 11.5, weight: FontWeight.w600, color: color, height: 1.3),
      ),
    );
  }
}

enum AdminButtonKind { primary, secondary, danger }

class AdminButton extends StatelessWidget {
  const AdminButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.kind = AdminButtonKind.secondary,
    this.compact = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final AdminButtonKind kind;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null && !loading;

    late final Color text;
    late final BoxDecoration decoration;
    switch (kind) {
      case AdminButtonKind.primary:
        text = const Color(0xFF0A0A0A);
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: <Color>[AppColors.cyan, AppColors.teal]),
        );
      case AdminButtonKind.danger:
        text = const Color(0xFFF87171);
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color.fromRGBO(239, 68, 68, 0.10),
          border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.30)),
        );
      case AdminButtonKind.secondary:
        text = Colors.white;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.whiteA(0.08),
          border: Border.all(color: AppColors.whiteA(0.14)),
        );
    }

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: compact ? 34 : 42,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
            decoration: decoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: compact ? 15 : 17, color: text),
                  const SizedBox(width: 7),
                ],
                Text(
                  loading ? 'Procesando...' : label,
                  style: AppText.body(
                    size: compact ? 12.5 : 14,
                    weight: FontWeight.w600,
                    color: text,
                    height: 1.2,
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

/// Chips de selección única.
class AdminChoiceChips<T> extends StatelessWidget {
  const AdminChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (T value, String label) in options)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: value == selected ? AppColors.cyanA(0.22) : AppColors.whiteA(0.06),
                  border: Border.all(
                    color: value == selected ? AppColors.cyanA(0.55) : AppColors.whiteA(0.10),
                  ),
                ),
                child: Text(
                  label,
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: value == selected ? AppColors.cyan : AppColors.whiteA(0.70),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Campo de texto con etiqueta y marco del diseño.
class AdminTextField extends StatefulWidget {
  const AdminTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint = '',
    this.maxLines = 1,
    this.keyboardType,
    this.digitsOnly = false,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool digitsOnly;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<AdminTextField> createState() => _AdminTextFieldState();
}

class _AdminTextFieldState extends State<AdminTextField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool multi = widget.maxLines > 1;

    final Widget field = FzFieldFrame(
      focused: _focus.hasFocus,
      height: multi ? null : 44,
      minHeight: multi ? 88 : 0,
      alignment: multi ? Alignment.topLeft : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: multi ? 10 : 0),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        minLines: multi ? 3 : 1,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType ?? (multi ? TextInputType.multiline : TextInputType.text),
        inputFormatters: <TextInputFormatter>[
          if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength),
        ],
        onChanged: widget.onChanged,
        cursorColor: Colors.white,
        style: AppText.body(size: 15, color: Colors.white, height: multi ? 1.45 : null),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hint,
          hintStyle: AppText.body(size: 15, color: AppColors.whiteA(0.35), height: multi ? 1.45 : null),
        ),
      ),
    );

    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[FzLabel(widget.label!), const SizedBox(height: 6), field],
    );
  }
}

/// Campo de búsqueda con espera de 400 ms antes de avisar.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AdminTextField(
            controller: _controller,
            hint: widget.hint,
            onChanged: _changed,
          ),
        ),
      ],
    );
  }
}

class AdminEmpty extends StatelessWidget {
  const AdminEmpty({super.key, required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 40, color: AppColors.whiteA(0.30)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppText.body(size: 13, color: AppColors.whiteA(0.45), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Diálogos, hojas y avisos
// ═══════════════════════════════════════════════════════════════════════════

Future<bool> adminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = true,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xB3000000),
    builder: (BuildContext ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
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
                title,
                textAlign: TextAlign.center,
                style: AppText.display(size: 20, weight: FontWeight.w700, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body(size: 14, color: AppColors.whiteA(0.60), height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: AdminButton(label: 'Cancelar', onTap: () => Navigator.of(ctx).pop(false)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: AdminButton(
                        label: confirmLabel,
                        kind: danger ? AdminButtonKind.danger : AdminButtonKind.primary,
                        onTap: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result == true;
}

/// Hoja inferior con título y contenido que hace scroll.
class AdminSheet extends StatelessWidget {
  const AdminSheet({super.key, required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFA0A0A0A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.whiteA(0.10))),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
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
                  style: AppText.display(size: 20, weight: FontWeight.w700, height: 1.4),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppText.body(size: 14, color: AppColors.whiteA(0.50), height: 1.43),
                  ),
                ],
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAdminSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000),
    constraints: const BoxConstraints(maxWidth: 640),
    builder: builder,
  );
}

void adminToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppText.body(size: 14, color: error ? const Color(0xFFF87171) : Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        backgroundColor: const Color(0xFF111111),
        duration: Duration(seconds: error ? 4 : 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.whiteA(0.12)),
        ),
      ),
    );
}