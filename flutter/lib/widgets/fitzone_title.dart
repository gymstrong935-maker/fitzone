import 'package:flutter/material.dart';

class FitZoneTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const FitZoneTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF05C8D8),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}