import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// SSU 로고 위젯. assets/images/ssu_logo.png가 있으면 이미지 사용, 없으면 텍스트 로고.
class SsuLogo extends StatelessWidget {
  const SsuLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkBlue, AppColors.mediumBlue, AppColors.lightBlue],
        ),
      ),
      child: Center(
        child: Text(
          'SSU',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
