import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Transición de páginas: aparece con fundido y sube suavemente (sin el salto
/// brusco de la transición por defecto de cada plataforma).
class FzPageTransitionsBuilder extends PageTransitionsBuilder {
  const FzPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // La pantalla que queda debajo se aleja un poquito y se atenúa.
    final Animation<double> behind = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.97).animate(behind),
          child: child,
        ),
      ),
    );
  }
}

/// Scroll con rebote suave en todas las plataformas y arrastre con mouse/trackpad.
class FzScrollBehavior extends MaterialScrollBehavior {
  const FzScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  // Sin el resplandor azul de Android al llegar al final.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(light: false);
  static ThemeData get light => _build(light: true);

  static ThemeData _build({required bool light}) {
    final Brightness brightness = light ? Brightness.light : Brightness.dark;
    final ThemeData base = ThemeData(brightness: brightness, useMaterial3: true);

    final Color ink = light ? const Color(0xFF0F172A) : Colors.white;
    final Color bg = light ? const Color(0xFFF4F7FB) : Colors.black;
    final Color surface = light ? Colors.white : const Color(0xFF0F0F0F);

    final ColorScheme scheme = light
        ? const ColorScheme.light(
            primary: AppColors.cyan,
            onPrimary: AppColors.onAccent,
            secondary: AppColors.teal,
            onSecondary: AppColors.onAccent,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
            error: AppColors.destructive,
          )
        : const ColorScheme.dark(
            primary: AppColors.cyan,
            onPrimary: AppColors.onAccent,
            secondary: AppColors.teal,
            onSecondary: AppColors.onAccent,
            surface: AppColors.background,
            error: AppColors.destructive,
          );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      canvasColor: surface,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      // Sin la onda gris de Material: el feedback lo dan las escalas y los colores.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.cyan.withValues(alpha: 0.06),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FzPageTransitionsBuilder(),
          TargetPlatform.iOS: FzPageTransitionsBuilder(),
          TargetPlatform.macOS: FzPageTransitionsBuilder(),
          TargetPlatform.windows: FzPageTransitionsBuilder(),
          TargetPlatform.linux: FzPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FzPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ink.withValues(alpha: 0.12)),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.all(ink.withValues(alpha: 0.18)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cyan,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ink.withValues(alpha: 0.12)),
        ),
        textStyle: TextStyle(color: ink, fontSize: 12),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: AppColors.cyan.withValues(alpha: 0.30),
        selectionHandleColor: AppColors.cyan,
      ),
      // Las fuentes (Exo 2 y Outfit) se aplican en cada texto con AppText.
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    );
  }
}
