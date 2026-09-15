import 'package:flutter/material.dart';

class FitZoneCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FitZoneCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: child,
    );
  }
}