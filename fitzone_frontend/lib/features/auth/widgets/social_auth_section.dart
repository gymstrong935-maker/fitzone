import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

const String _googleSvg = r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#EA4335" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#4A90D9" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#FBBC05" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

const String _appleSvg = r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white">
  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
</svg>
''';

/// Separador "O continuar con" + botones de Google y Apple.
class SocialAuthSection extends StatelessWidget {
  const SocialAuthSection({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;

  /// Recibe el nombre del proveedor: "Google" o "Apple".
  final ValueChanged<String> onPressed;

  Widget _line() => Expanded(
        child: Container(height: 1, color: AppColors.whiteA(0.09)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            _line(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'O continuar con',
                style: AppText.body(
                  size: 11.68,
                  color: AppColors.whiteA(0.32),
                  letterSpacing: 0.47,
                ),
              ),
            ),
            _line(),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: _SocialButton(
                label: 'Google',
                svg: _googleSvg,
                enabled: enabled,
                onTap: () => onPressed('Google'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SocialButton(
                label: 'Apple',
                svg: _appleSvg,
                enabled: enabled,
                onTap: () => onPressed('Apple'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.label,
    required this.svg,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String svg;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _setPressing(true) : null,
      onTapUp: (_) => _setPressing(false),
      onTapCancel: () => _setPressing(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressing ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.whiteA(0.11)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.string(widget.svg, width: 17, height: 17),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppText.body(size: 13.6, color: AppColors.whiteA(0.78)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}