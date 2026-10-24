import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/sub_screen_frame.dart';
import '../support/widgets/support_sheets.dart';
import 'assistant_controller.dart';

const List<String> _staffSuggestions = <String>[
  '¿Cómo va el negocio hoy?',
  '¿Qué pagos faltan por validar?',
  '¿Quién vence esta semana?',
  '¿Hay tickets de soporte abiertos?',
];

const List<String> _suggestions = <String>[
  '¿Qué planes tienen?',
  '¿Cómo agendo una cita?',
  '¿Cuándo vence mi plan?',
  'Mi pago no se ha aprobado',
];

/// Pantalla "Soporte": chat con la IA + contacto con una persona.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.controller,
    required this.onBack,
    this.staff = false,
  });

  final AssistantController controller;
  final VoidCallback onBack;

  /// `true` para el equipo del panel admin: ve datos del negocio y no se le
  /// ofrece "Hablar con una persona".
  final bool staff;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollToEnd);
    _input.addListener(_rebuild);
    _focus.addListener(_rebuild);
    _scrollToEnd();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToEnd);
    _input.removeListener(_rebuild);
    _focus.removeListener(_rebuild);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? preset]) {
    final String text = (preset ?? _input.text).trim();
    if (text.isEmpty || widget.controller.sending) return;
    _input.clear();
    widget.controller.send(text);
  }

  Future<void> _contactSupport() async {
    await showSupportRequestSheet(context, transcript: widget.controller.transcript);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final AssistantController c = widget.controller;
        final List<ChatMessage> messages = c.messages;
        final bool showSuggestions = c.isFresh && !c.sending;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SubScreenHeader(
              title: widget.staff ? 'Asistente del equipo' : 'Soporte FitZone',
              subtitle: widget.staff
                  ? 'Consulta usuarios, pagos, vencimientos y más'
                  : 'Asistente con IA · respuestas al instante',
              onBack: widget.onBack,
            ),
            _buildToolbar(c),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    children: <Widget>[
                      for (final ChatMessage m in messages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _Bubble(
                            message: m,
                            onRetry: m.isError && !c.sending ? c.retry : null,
                            onContact: m.isError && !widget.staff ? _contactSupport : null,
                          ),
                        ),
                      if (c.sending)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _TypingBubble(),
                        ),
                      if (showSuggestions) _buildSuggestions(),
                    ],
                  ),
                ),
              ),
            ),
            _buildInputBar(c.sending),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(AssistantController c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.whiteA(0.06))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512 - 32),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (!widget.staff) ...<Widget>[
                _ToolChip(
                  icon: Icons.headset_mic_outlined,
                  label: 'Hablar con una persona',
                  highlighted: true,
                  onTap: _contactSupport,
                ),
                _ToolChip(
                  icon: Icons.forum_outlined,
                  label: 'Mis solicitudes',
                  onTap: () => showMyTicketsSheet(context),
                ),
              ],
              if (!c.isFresh && !c.sending)
                _ToolChip(
                  icon: Icons.restart_alt_rounded,
                  label: 'Nueva conversación',
                  onTap: c.clear,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 38),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final String s in (widget.staff ? _staffSuggestions : _suggestions))
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _send(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cyanA(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.cyanA(0.25)),
                  ),
                  child: Text(
                    s,
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.cyanLightText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool sending) {
    final double bottom = MediaQuery.paddingOf(context).bottom;
    final bool canSend = _input.text.trim().isNotEmpty && !sending;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.90),
        border: Border(top: BorderSide(color: AppColors.whiteA(0.08))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512 - 32),
          child: Row(
            children: <Widget>[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 46,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: AppColors.whiteA(0.08),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: _focus.hasFocus ? AppColors.cyan : AppColors.whiteA(0.15),
                    ),
                  ),
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    textInputAction: TextInputAction.send,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(500),
                    ],
                    onSubmitted: (_) => _send(),
                    cursorColor: AppColors.ink,
                    style: AppText.body(size: 15, color: AppColors.ink),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Escribe tu pregunta...',
                      hintStyle: AppText.body(size: 15, color: AppColors.whiteA(0.35)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Enviar',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canSend ? _send : null,
                  child: AnimatedOpacity(
                    opacity: canSend ? 1 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[AppColors.cyan, AppColors.teal],
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 22,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color color = highlighted ? AppColors.cyan : AppColors.whiteA(0.70);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.cyanA(0.12) : AppColors.whiteA(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlighted ? AppColors.cyanA(0.35) : AppColors.whiteA(0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.body(size: 12.5, weight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7C3AED), AppColors.cyan],
        ),
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry, this.onContact});

  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth.clamp(0, 400).toDouble()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[AppColors.cyan, AppColors.teal],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message.text,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                color: const Color(0xFF0A0A0A),
                height: 1.45,
              ),
            ),
          ),
        ),
      );
    }

    final bool error = message.isError;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _AssistantAvatar(),
        const SizedBox(width: 10),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth.clamp(0, 400).toDouble()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.whiteA(0.06),
                border: Border.all(color: AppColors.whiteA(0.10)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    message.text,
                    style: AppText.body(
                      size: 14,
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                  if (onRetry != null || onContact != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: <Widget>[
                        if (onRetry != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onRetry,
                            child: Text(
                              'Reintentar',
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        if (onContact != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onContact,
                            child: Text(
                              'Hablar con una persona',
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: AppColors.cyanText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const _AssistantAvatar(),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.06),
            border: Border.all(color: AppColors.whiteA(0.10)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: const PulsingDots(dotSize: 6, gap: 5),
        ),
      ],
    );
  }
}