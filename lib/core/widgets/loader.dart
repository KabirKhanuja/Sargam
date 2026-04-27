import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppLoader extends StatelessWidget {
  final double size;
  const AppLoader({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(AppColors.gold),
      ),
    );
  }
}
