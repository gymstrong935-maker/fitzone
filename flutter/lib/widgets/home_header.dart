import 'package:flutter/material.dart';

import 'package:fitzone/widgets/fitzone_logo.dart';
import 'package:fitzone/widgets/fitzone_button.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const HomeHeader({
    super.key,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const FitZoneLogo(
            size: 50,
          ),

          const Spacer(),

          SizedBox(
            width: 110,
            child: FitZoneButton(
              text: 'INGRESAR',
              onPressed: onLoginPressed,
              outlined: true,
            ),
          ),
        ],
      ),
    );
  }
}