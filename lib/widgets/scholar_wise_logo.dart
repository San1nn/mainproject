import 'package:flutter/material.dart';
import 'package:mainproject/constants.dart';

class ScholarWiseLogo extends StatelessWidget {
  final double fontSize;
  final bool usePrimaryColor;

  const ScholarWiseLogo({
    super.key,
    this.fontSize = 22,
    this.usePrimaryColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Scholar',
            style: TextStyle(
              color: usePrimaryColor ? AppColors.primary : Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          TextSpan(
            text: 'Wise',
            style: TextStyle(
              color: usePrimaryColor ? AppColors.textPrimary : Colors.white70,
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }
}
