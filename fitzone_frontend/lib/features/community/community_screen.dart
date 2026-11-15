import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/app_services.dart';
import '../../core/services/community_service.dart';
import '../../core/services/workouts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/sub_screen_frame.dart';
import '../history/workouts_controller.dart';

const int _pageSize = 15;

const List<List<Color>> _avatarGradients = <List<Color>>[
  <Color>[Color(0xFF3B82F6), Color(0xFF06B6D4)],
  <Color>[Color(0xFFEC4899), Color(0xFFA855F7)],
  <Color>[Color(0xFFF97316), Color(0xFFEF4444)],
  <Color>[Color(0xFF10B981), Color(0xFF14B8A6)],
  <Color>[Color(0xFF8B5CF6), Color(0xFF6366F1)],
  <Color>[Color(0xFFF59E0B), Color(0xFFF97316)],
];

/// Cada persona siempre tiene el mismo color de avatar.
List<Color> _gradientFor(String seed) {
  int hash = 0;
  for (final int unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _avatarGradients[hash % _avatarGradients.length];
}

/// Pantalla "Comunidad": muro con los entrenamientos y logros de todos.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    super.key,
    required this.workouts,
    required this.onBack,
  });

  /// Historial del usuario (para elegir qué entrenamiento compartir).
  final WorkoutsController workouts;
  final VoidCallback onBack;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _service = AppServices.instance.community;

  List<CommunityPost> _posts = <CommunityPost>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Datos ─────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final List<CommunityPost> posts = await _service.feed(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _hasMore = posts.length >= _pageSize;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _posts.isEmpty) return;
    setState(() => _loadingMore = true);

    try {
      final List<CommunityPost> next =
          await _service.feed(before: _posts.last.id, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        final Set<String> known = <String>{for (final CommunityPost p in _posts) p.id};
        _posts = <CommunityPost>[
          ..._posts,
          for (final CommunityPost p in next)
            if (!known.contains(p.id)) p,
        ];
        _hasMore = next.length >= _pageSize;
      });
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _update(String id, CommunityPost Function(CommunityPost) change) {
    setState(() {
      _posts = <CommunityPost>[
        for (final CommunityPost p in _posts) p.id == id ? change(p) : p,
      ];
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppText.body(size: 14, color: AppColors.ink)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.whiteA(0.12)),
          ),
        ),
      );
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _share() async {
    // Solo los entrenamientos que ya llegaron al servidor se pueden compartir.
    final List<SavedWorkout> candidates = widget.workouts.sessions
        .where((SavedWorkout w) => !w.pending && w.id.isNotEmpty)
        .take(5)
        .toList();

    final CommunityPost? created = await showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      constraints: const BoxConstraints(maxWidth: 512),
      builder: (BuildContext ctx) =>
          _ShareSheet(service: _service, workouts: candidates),
    );

    if (created == null || !mounted) return;
    setState(() => _posts = <CommunityPost>[created, ..._posts]);
    _toast('¡Publicado en la comunidad!');
  }

  Future<void> _toggleLike(CommunityPost post) async {
    final CommunityPost before = post;
    final bool nextLiked = !before.liked;

    // Se refleja al instante y, si el servidor falla, se devuelve.
    _update(
      post.id,
      (CommunityPost p) => p.copyWith(
        liked: nextLiked,
        likes: before.likes + (nextLiked ? 1 : -1),
      ),
    );

    try {
      final result = await _service.toggleLike(post.id);
      if (!mounted) return;
      _update(
        post.id,
        (CommunityPost p) => p.copyWith(liked: result.liked, likes: result.likes),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _update(
        post.id,
        (CommunityPost p) => p.copyWith(liked: before.liked, likes: before.likes),
      );
      _toast(e.message);
    }
  }

  Future<void> _delete(CommunityPost post) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (BuildContext ctx) => const _ConfirmDialog(
        title: '¿Eliminar tu publicación?',
        message: 'Se borrará también con sus comentarios. No se puede deshacer.',
        confirmLabel: 'Eliminar',
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _posts = <CommunityPost>[
          for (final CommunityPost p in _posts)
            if (p.id != post.id) p,
        ];
      });
      _toast('Publicación eliminada');
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _openComments(CommunityPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      constraints: const BoxConstraints(maxWidth: 512),
      builder: (BuildContext ctx) => _CommentsSheet(
        service: _service,
        postId: post.id,
        onCountChanged: (int count) =>
            _update(post.id, (CommunityPost p) => p.copyWith(comments: count)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SubScreenFrame(
      title: 'Comunidad',
      subtitle: 'Comparte tu progreso',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _GradientButton(label: 'Compartir mi entrenamiento', onTap: _share)),
              const SizedBox(width: 10),
              PressableScale(
                onTap: _loading ? null : _load,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.whiteA(0.06),
                    border: Border.all(color: AppColors.whiteA(0.10)),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 20, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildFeed(),
        ],
      ),
    );
  }

  List<Widget> _buildFeed() {
    if (_loading) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
        ),
      ];
    }

    if (_error.isNotEmpty) {
      return <Widget>[
        ErrorBox(_error),
        const SizedBox(height: 12),
        PressableScale(
          onTap: _load,
          child: Center(
            child: Text(
              'Reintentar',
              style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.cyanLightText),
            ),
          ),
        ),
      ];
    }

    if (_posts.isEmpty) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.whiteA(0.09)),
          ),
          child: Column(
            children: <Widget>[
              Icon(Icons.groups_rounded, size: 32, color: AppColors.whiteA(0.45)),
              const SizedBox(height: 12),
              Text(
                'Aún no hay publicaciones',
                textAlign: TextAlign.center,
                style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Sé la primera persona en compartir su progreso.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 13, color: AppColors.whiteA(0.50), height: 1.5),
              ),
            ],
          ),
        ),
      ];
    }

    return <Widget>[
      for (int i = 0; i < _posts.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: 12),
        FadeSlideIn(
          key: ValueKey<String>(_posts[i].id),
          delay: Duration(milliseconds: (i % 8) * 60),
          duration: const Duration(milliseconds: 400),
          offsetY: 8,
          child: _PostCard(
            post: _posts[i],
            onLike: () => _toggleLike(_posts[i]),
            onComment: () => _openComments(_posts[i]),
            onDelete: () => _delete(_posts[i]),
          ),
        ),
      ],
      if (_hasMore) ...<Widget>[
        const SizedBox(height: 16),
        _loadingMore
            ? const Center(child: PulsingDots(dotSize: 6, gap: 6))
            : PressableScale(
                onTap: _loadMore,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: AppColors.whiteA(0.06),
                    border: Border.all(color: AppColors.whiteA(0.10)),
                  ),
                  child: Text(
                    'Ver más publicaciones',
                    style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
              ),
      ],
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Publicación
// ═══════════════════════════════════════════════════════════════════════════

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color likeColor = post.liked ? AppColors.red : AppColors.whiteA(0.45);
    final SharedWorkout? workout = post.workout;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Avatar(author: post.author, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      post.author.name,
                      style: AppText.display(size: 14, weight: FontWeight.w600, height: 1.43),
                    ),
                    Text(
                      formatRelativeTime(post.createdAt),
                      style: AppText.body(size: 12, color: AppColors.whiteA(0.40), height: 1.333),
                    ),
                  ],
                ),
              ),
              if (post.mine)
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  color: AppColors.surface,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.whiteA(0.45)),
                  onSelected: (String _) => onDelete(),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        'Eliminar publicación',
                        style: AppText.body(size: 14, color: AppColors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (post.text.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              post.text,
              style: AppText.body(size: 14, color: AppColors.whiteA(0.80), height: 1.625),
            ),
          ],
          if (workout != null) ...<Widget>[
            const SizedBox(height: 12),
            _WorkoutSummary(workout: workout),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.whiteA(0.06))),
            ),
            child: Row(
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: likeColor,
                      ),
                      const SizedBox(width: 6),
                      Text('${post.likes}', style: AppText.body(size: 12, color: likeColor, height: 1.333)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onComment,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.chat_bubble_outline_rounded, size: 17, color: AppColors.whiteA(0.45)),
                      const SizedBox(width: 6),
                      Text(
                        post.comments == 0 ? 'Comentar' : '${post.comments}',
                        style: AppText.body(size: 12, color: AppColors.whiteA(0.45), height: 1.333),
                      ),
                    ],
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

class _WorkoutSummary extends StatelessWidget {
  const _WorkoutSummary({required this.workout});

  final SharedWorkout workout;

  @override
  Widget build(BuildContext context) {
    final List<SharedExercise> shown = workout.exercises.take(4).toList();
    final int extra = workout.exercises.length - shown.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyanA(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.fitness_center_rounded, size: 16, color: AppColors.cyanLightText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  workout.title,
                  style: AppText.display(size: 14, weight: FontWeight.w700, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: <Widget>[
              if (workout.durationMinutes > 0) _Stat(icon: Icons.timer_outlined, text: '${workout.durationMinutes} min'),
              if (workout.calories > 0) _Stat(icon: Icons.local_fire_department_outlined, text: '${workout.calories} kcal'),
              _Stat(icon: Icons.list_alt_rounded, text: '${workout.exercises.length} ejercicios'),
            ],
          ),
          if (shown.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final SharedExercise e in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${e.name} · ${e.sets}×${e.reps}',
                  style: AppText.body(size: 12.5, color: AppColors.whiteA(0.65), height: 1.5),
                ),
              ),
            if (extra > 0)
              Text(
                '+ $extra más',
                style: AppText.body(size: 12.5, color: AppColors.whiteA(0.40), height: 1.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.whiteA(0.55)),
        const SizedBox(width: 4),
        Text(text, style: AppText.body(size: 12, color: AppColors.whiteA(0.65), height: 1.333)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.author, required this.size});

  final CommunityAuthor author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = _gradientFor(author.id.isEmpty ? author.name : author.id);

    final Widget initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Text(
        author.initials,
        style: AppText.body(
          size: size * 0.3,
          weight: FontWeight.w700,
          color: Colors.white,
          height: 1.333,
        ),
      ),
    );

    if (author.photo.isEmpty) return initials;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          author.photo,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext c, Object e, StackTrace? s) => initials,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Compartir un entrenamiento
// ═══════════════════════════════════════════════════════════════════════════

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.service, required this.workouts});

  final CommunityService service;
  final List<SavedWorkout> workouts;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final TextEditingController _text = TextEditingController();

  late String? _selectedId =
      widget.workouts.isEmpty ? null : widget.workouts.first.id;
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ready =>
      !_busy && (_selectedId != null || _text.text.trim().isNotEmpty);

  Future<void> _publish() async {
    if (!_ready) return;

    setState(() {
      _busy = true;
      _error = '';
    });

    try {
      final CommunityPost post = await widget.service.publish(
        text: _text.text,
        workoutId: _selectedId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(post);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Compartir mi entrenamiento',
      subtitle: 'Lo verá toda la comunidad de FitZone',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.workouts.isEmpty)
            Text(
              'Aún no tienes entrenamientos guardados. Por ahora puedes publicar solo un mensaje.',
              style: AppText.body(size: 13, color: AppColors.whiteA(0.50), height: 1.5),
            )
          else ...<Widget>[
            Text(
              'Elige un entrenamiento',
              style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.whiteA(0.70)),
            ),
            const SizedBox(height: 8),
            for (final SavedWorkout w in widget.workouts) ...<Widget>[
              _WorkoutTile(
                workout: w,
                selected: _selectedId == w.id,
                onTap: () => setState(() => _selectedId = _selectedId == w.id ? null : w.id),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLength: 280,
            maxLines: 3,
            minLines: 2,
            onChanged: (String _) => setState(() {}),
            style: AppText.body(size: 14, color: AppColors.ink),
            decoration: _inputDecoration('Cuéntale a la comunidad cómo te fue… (opcional)'),
          ),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ErrorBox(_error),
          ],
          const SizedBox(height: 12),
          _GradientButton(
            label: _busy ? 'Publicando...' : 'Publicar',
            onTap: _ready ? _publish : null,
          ),
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({
    required this.workout,
    required this.selected,
    required this.onTap,
  });

  final SavedWorkout workout;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = <String>[
      formatRelativeTime(workout.date),
      if (workout.durationMinutes > 0) '${workout.durationMinutes} min',
      if (workout.calories > 0) '${workout.calories} kcal',
      '${workout.exerciseCount} ejercicios',
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? AppColors.cyanA(0.12) : AppColors.whiteA(0.05),
          border: Border.all(
            color: selected ? AppColors.cyanA(0.55) : AppColors.whiteA(0.10),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    workout.title,
                    style: AppText.display(size: 14, weight: FontWeight.w700, height: 1.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parts.join(' · '),
                    style: AppText.body(size: 12, color: AppColors.whiteA(0.50), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.cyanLightText : AppColors.whiteA(0.30),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Comentarios
// ═══════════════════════════════════════════════════════════════════════════

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.service,
    required this.postId,
    required this.onCountChanged,
  });

  final CommunityService service;
  final String postId;

  /// Avisa cuántos comentarios tiene la publicación después de agregar o borrar.
  final ValueChanged<int> onCountChanged;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _text = TextEditingController();

  List<CommunityComment> _items = <CommunityComment>[];
  bool _loading = true;
  bool _sending = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<CommunityComment> items = await widget.service.comments(widget.postId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _send() async {
    final String text = _text.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = '';
    });

    try {
      final CommunityComment created = await widget.service.addComment(widget.postId, text);
      if (!mounted) return;
      _text.clear();
      setState(() {
        _items = <CommunityComment>[..._items, created];
        _sending = false;
      });
      widget.onCountChanged(_items.length);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  Future<void> _remove(CommunityComment comment) async {
    try {
      await widget.service.deleteComment(widget.postId, comment.id);
      if (!mounted) return;
      setState(() {
        _items = <CommunityComment>[
          for (final CommunityComment c in _items)
            if (c.id != comment.id) c,
        ];
      });
      widget.onCountChanged(_items.length);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget list;

    if (_loading) {
      list = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
      );
    } else if (_items.isEmpty) {
      list = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Todavía no hay comentarios. ¡Escribe el primero!',
          textAlign: TextAlign.center,
          style: AppText.body(size: 13, color: AppColors.whiteA(0.50), height: 1.5),
        ),
      );
    } else {
      list = ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 14),
        itemBuilder: (BuildContext c, int i) => _CommentRow(
          comment: _items[i],
          onDelete: () => _remove(_items[i]),
        ),
      );
    }

    return _SheetFrame(
      title: 'Comentarios',
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(child: list),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ErrorBox(_error),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _text,
                  maxLength: 300,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (String _) => _send(),
                  style: AppText.body(size: 14, color: AppColors.ink),
                  decoration: _inputDecoration('Escribe un comentario…').copyWith(counterText: ''),
                ),
              ),
              const SizedBox(width: 10),
              PressableScale(
                onTap: _sending ? null : _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: <Color>[AppColors.cyan, AppColors.teal]),
                  ),
                  child: Icon(
                    _sending ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment, required this.onDelete});

  final CommunityComment comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Avatar(author: comment.author, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      comment.author.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(size: 13, weight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatRelativeTime(comment.createdAt),
                    style: AppText.body(size: 11, color: AppColors.whiteA(0.40), height: 1.4),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                comment.text,
                style: AppText.body(size: 13.5, color: AppColors.whiteA(0.80), height: 1.45),
              ),
            ],
          ),
        ),
        if (comment.canDelete)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.whiteA(0.40)),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas comunes
// ═══════════════════════════════════════════════════════════════════════════

InputDecoration _inputDecoration(String hint) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(size: 14, color: AppColors.whiteA(0.35)),
    filled: true,
    fillColor: AppColors.whiteA(0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    counterStyle: AppText.body(size: 11, color: AppColors.whiteA(0.35)),
    border: border(AppColors.whiteA(0.10)),
    enabledBorder: border(AppColors.whiteA(0.10)),
    focusedBorder: border(AppColors.cyanA(0.55)),
  );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: <Color>[AppColors.cyan, AppColors.teal],
            ),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w600,
              color: Colors.black,
              height: 1.43,
            ),
          ),
        ),
      ),
    );
  }
}

/// Marco de las hojas inferiores: asa, título y contenido.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
    this.subtitle,
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// `true`: el contenido se desplaza si no cabe. `false`: el contenido se
  /// encarga solo (lo usan los comentarios, que tienen su propia lista).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.glass(0.98),
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
              style: AppText.display(size: 20, weight: FontWeight.w700, height: 1.4),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppText.body(size: 14, color: AppColors.whiteA(0.50), height: 1.43),
              ),
            ],
            const SizedBox(height: 12),
            if (scrollable)
              Flexible(child: SingleChildScrollView(child: child))
            else
              Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    Widget button(String label, Color bg, Color border, Color fg, bool result) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(result),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
            child: Text(
              label,
              style: AppText.body(size: 14, weight: FontWeight.w600, color: fg, height: 1.43),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                style: AppText.body(size: 14, color: AppColors.whiteA(0.60), height: 1.43),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  button('Cancelar', AppColors.whiteA(0.08), AppColors.whiteA(0.12), AppColors.ink, false),
                  const SizedBox(width: 12),
                  button(
                    confirmLabel,
                    const Color.fromRGBO(239, 68, 68, 0.12),
                    const Color.fromRGBO(239, 68, 68, 0.30),
                    AppColors.red,
                    true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
