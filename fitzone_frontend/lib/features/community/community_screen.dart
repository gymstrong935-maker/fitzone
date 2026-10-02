import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/sub_screen_frame.dart';
import 'data/community_data.dart';

/// Pantalla "Comunidad".
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SubScreenFrame(
      title: 'Comunidad',
      subtitle: 'Comparte tu progreso',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Botón "Compartir" (el diseño aún no define ninguna acción).
          PressableScale(
            onTap: null,
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
                'Compartir mi entrenamiento',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.43,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          for (int i = 0; i < kPosts.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            FadeSlideIn(
              delay: Duration(milliseconds: i * 70),
              duration: const Duration(milliseconds: 400),
              offsetY: 8,
              child: _PostCard(post: kPosts[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  static const Color _red400 = Color(0xFFF87171);

  late bool _liked = widget.post.liked;
  late int _likes = widget.post.likes;

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CommunityPost p = widget.post;
    final Color likeColor = _liked ? _red400 : AppColors.whiteA(0.45);

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
          // ── Autor ──
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[p.from, p.to],
                  ),
                ),
                child: Text(
                  p.initials,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.333,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      p.user,
                      style: AppText.display(
                        size: 14,
                        weight: FontWeight.w600,
                        height: 1.43,
                      ),
                    ),
                    Text(
                      p.time,
                      style: AppText.body(
                        size: 12,
                        color: AppColors.whiteA(0.40),
                        height: 1.333,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Contenido ──
          Text(
            p.workout,
            style: AppText.body(
              size: 14,
              color: AppColors.whiteA(0.80),
              height: 1.625,
            ),
          ),
          const SizedBox(height: 12),

          // ── Acciones ──
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.whiteA(0.06))),
            ),
            child: Row(
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: likeColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_likes',
                        style: AppText.body(
                          size: 12,
                          color: likeColor,
                          height: 1.333,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '💬 Comentar',
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.40),
                    height: 1.333,
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