import 'package:flutter/material.dart';

class FitZoneLogo extends StatelessWidget {
  final double size;

  const FitZoneLogo({
    super.key,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF05C8D8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          'FZ',
          style: TextStyle(
            color: Colors.black,
            fontSize: size * 0.30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}