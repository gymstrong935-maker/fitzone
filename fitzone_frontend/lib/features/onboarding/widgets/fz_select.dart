import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'fz_field_frame.dart';

class FzSelectOption<T> {
  const FzSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Selector desplegable con el estilo de los demás campos.
class FzSelect<T> extends StatelessWidget {
  const FzSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<FzSelectOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final String currentLabel = options
        .firstWhere(
          (FzSelectOption<T> o) => o.value == value,
          orElse: () => options.first,
        )
        .label;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // El menú mide lo mismo que el campo (mínimo 128 px, como el diseño).
        final double menuWidth =
            constraints.maxWidth < 128 ? 128 : constraints.maxWidth;

        return PopupMenuButton<T>(
          tooltip: '',
          position: PopupMenuPosition.under,
          offset: const Offset(0, 4),
          color: const Color(0xF20F0F0F),
          elevation: 8,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black,
          constraints: BoxConstraints(minWidth: menuWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.whiteA(0.10)),
          ),
          onSelected: onChanged,
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<T>>[
              for (final FzSelectOption<T> option in options)
                PopupMenuItem<T>(
                  value: option.value,
                  height: 36,
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            option.label,
                            style: AppText.body(size: 14, color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          child: option.value == value
                              ? const Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ];
          },
          child: FzFieldFrame(
            focused: false,
            height: 44,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    currentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.whiteA(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}