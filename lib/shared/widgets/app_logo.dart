import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool onDark;

  const AppLogo({super.key, this.size = 48, this.showText = false, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IconeLogo(size: size),
        if (showText) ...[
          SizedBox(width: size * 0.22),
          Text(
            'AquiBank',
            style: GoogleFonts.interTight(
              color: onDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: size * 0.52,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _IconeLogo extends StatelessWidget {
  final double size;
  const _IconeLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.gradientPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'AB',
          style: GoogleFonts.interTight(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            letterSpacing: -size * 0.02,
          ),
        ),
      ),
    );
  }
}

class AppLogoGlow extends StatelessWidget {
  final double size;
  const AppLogoGlow({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size * 1.8,
          height: size * 1.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.28),
                AppColors.primary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        _IconeLogo(size: size),
      ],
    );
  }
}
