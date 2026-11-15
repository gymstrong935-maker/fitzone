import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/error_box.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/pulsing_dots.dart';
import '../widgets/admin_widgets.dart';

/// Historial de cambios: qué hizo cada usuario (y el equipo) dentro de la app.
class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  static const int _pageSize = 40;

  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  String _query = '';
  String _category = '';
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _request = 0; // descarta respuestas viejas si el filtro cambió

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    final int ticket = ++_request;
    setState(() {
      if (reset) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final Map<String, dynamic> data = await widget.service.activity(
        q: _query,
        categoria: _category,
        skip: reset ? 0 : _items.length,
        limit: _pageSize,
      );
      if (!mounted || ticket != _request) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(asList(data['registros']));
        _total = asNum(data['total']).toInt();
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || ticket != _request) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Historial de cambios',
      subtitle: 'Lo que hace cada usuario en la app: perfil, salud, entrenamientos, citas, pagos y más',
      actions: <Widget>[
        AdminButton(
          label: 'Actualizar',
          icon: Icons.refresh_rounded,
          compact: true,
          onTap: _loading ? null : () => _load(reset: true),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminSearchField(
            hint: 'Buscar por usuario, correo o acción',
            onChanged: (String v) {
              _query = v;
              _load(reset: true);
            },
          ),
          const SizedBox(height: 12),
          AdminChoiceChips<String>(
            options: <(String, String)>[
              ('', 'Todo'),
              for (final _Category c in _categories) (c.key, c.label),
            ],
            selected: _category,
            onChanged: (String v) {
              setState(() => _category = v);
              _load(reset: true);
            },
          ),
          const SizedBox(height: 18),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ErrorBox(_error!),
          const SizedBox(height: 12),
          AdminButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: () => _load(reset: true)),
        ],
      );
    }

    if (_items.isEmpty) {
      return const AdminEmpty(
        icon: Icons.history_toggle_off_rounded,
        title: 'Aún no hay movimientos',
        message: 'Cuando los usuarios cambien su perfil, entrenen o agenden citas, quedará registrado aquí.',
      );
    }

    final List<Widget> children = <Widget>[
      Text(
        '$_total ${_total == 1 ? 'movimiento' : 'movimientos'}',
        style: AppText.body(size: 12, color: AppColors.whiteA(0.40)),
      ),
      const SizedBox(height: 6),
    ];

    String lastDay = '';
    for (int i = 0; i < _items.length; i++) {
      final Map<String, dynamic> item = _items[i];
      final DateTime? date = asDate(item['fecha']);
      final String day = _dayLabel(date);

      if (day != lastDay) {
        lastDay = day;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              day,
              style: AppText.display(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.cyanText,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FadeSlideIn(
            // Se escalona solo dentro de la primera pantalla; el resto aparece al instante
            delay: Duration(milliseconds: i < 12 ? i * 25 : 0),
            duration: const Duration(milliseconds: 380),
            offsetY: 10,
            child: _ActivityTile(item: item, date: date),
          ),
        ),
      );
    }

    if (_error != null) {
      children.add(Padding(padding: const EdgeInsets.only(top: 6), child: ErrorBox(_error!)));
    }

    if (_items.length < _total) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: AdminButton(
              label: 'Ver más',
              icon: Icons.expand_more_rounded,
              loading: _loadingMore,
              onTap: () => _load(reset: false),
            ),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.date});

  final Map<String, dynamic> item;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final String category = str(item['categoria']);
    final _Category meta = _categoryOf(category);
    final String name = str(item['nombre']).isEmpty ? 'Usuario eliminado' : str(item['nombre']);
    final String email = str(item['email']);
    final bool staff = str(item['rol']) == 'admin';
    final Color color = meta.color();

    final String time = date == null
        ? ''
        : '${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}';

    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(34),
              border: Border.all(color: color.withAlpha(90)),
            ),
            child: Icon(meta.icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: name,
                        style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.ink, height: 1.4),
                      ),
                      TextSpan(
                        text: '  ${str(item['descripcion'])}',
                        style: AppText.body(size: 14, color: AppColors.whiteA(0.75), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    StatusBadge(label: staff ? 'Equipo · ${meta.label}' : meta.label, color: color),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: AppText.body(size: 12, color: AppColors.whiteA(0.42)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: AppText.body(size: 12, color: AppColors.whiteA(0.40))),
        ],
      ),
    );
  }
}

// ── Categorías ──────────────────────────────────────────────────────────────

class _Category {
  const _Category(this.key, this.label, this.icon, this.color);

  final String key;
  final String label;
  final IconData icon;
  final Color Function() color;
}

final List<_Category> _categories = <_Category>[
  _Category('cuenta', 'Cuenta', Icons.manage_accounts_outlined, () => AppColors.cyanText),
  _Category('perfil', 'Perfil', Icons.person_outline_rounded, () => AppColors.teal400),
  _Category('salud', 'Salud', Icons.favorite_border_rounded, () => AppColors.pink),
  _Category('entrenamiento', 'Entrenamiento', Icons.fitness_center_rounded, () => AppColors.green),
  _Category('citas', 'Citas', Icons.event_available_outlined, () => AppColors.blue),
  _Category('pagos', 'Pagos', Icons.payments_outlined, () => AppColors.amber),
  _Category('comunidad', 'Comunidad', Icons.forum_outlined, () => AppColors.purple),
  _Category('soporte', 'Soporte', Icons.support_agent_rounded, () => AppColors.orange),
  _Category('admin', 'Equipo', Icons.admin_panel_settings_outlined, () => AppColors.violet),
];

_Category _categoryOf(String key) => _categories.firstWhere(
      (_Category c) => c.key == key,
      orElse: () => _Category(key, key.isEmpty ? 'Otro' : key, Icons.history_rounded, () => AppColors.violet),
    );

String _dayLabel(DateTime? d) {
  if (d == null) return '—';
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(d.year, d.month, d.day);
  final int diff = today.difference(day).inDays;
  if (diff == 0) return 'HOY';
  if (diff == 1) return 'AYER';
  return shortDate(d).toUpperCase();
}
