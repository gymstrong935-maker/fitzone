import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/measurement_guides.dart';

/// Abre la hoja con las instrucciones para tomar una medida.
Future<void> showMeasureGuide(BuildContext context, MeasureGuide guide) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xBF000000),
    constraints: const BoxConstraints(maxWidth: 512),
    builder: (BuildContext ctx) => _MeasureGuideSheet(guide: guide),
  );
}

/// Pequeño botón "?" para poner debajo de cada campo de medición.
class MeasureHelpButton extends StatelessWidget {
  const MeasureHelpButton({super.key, required this.guide});

  final MeasureGuide guide;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '¿Cómo medir ${guide.title}?',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showMeasureGuide(context, guide),
        child: Padding(
          padding: const EdgeInsets.only(top: 4, right: 12, bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyanA(0.15),
                  border: Border.all(color: AppColors.cyanA(0.40)),
                ),
                child: Text(
                  '?',
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.cyanText,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '¿Cómo medir?',
                style: AppText.body(
                  size: 11,
                  color: AppColors.whiteA(0.45),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasureGuideSheet extends StatelessWidget {
  const _MeasureGuideSheet({required this.guide});

  final MeasureGuide guide;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.whiteA(0.10)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.whiteA(0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cyanA(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyanA(0.25)),
                    ),
                    child: Icon(
                      Icons.straighten_rounded,
                      size: 20,
                      color: AppColors.cyanText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '¿Cómo medir: ${guide.title}?',
                          style: AppText.display(
                            size: 18,
                            weight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        Text(
                          guide.tool,
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.45),
                            height: 1.333,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.whiteA(0.08),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyanA(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cyanA(0.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.place_outlined, size: 16, color: AppColors.cyanText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guide.where,
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < guide.steps.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyanA(0.15),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.cyanText,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          guide.steps[i],
                          style: AppText.body(
                            size: 14,
                            color: AppColors.whiteA(0.80),
                            height: 1.43,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.whiteA(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.whiteA(0.09)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guide.tip,
                        style: AppText.body(
                          size: 12,
                          color: AppColors.whiteA(0.65),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
