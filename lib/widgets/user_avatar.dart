import 'package:flutter/material.dart';
import 'package:mainproject/constants.dart';

class UserAvatar extends StatelessWidget {
  final String seed;
  final String fallbackInitial;
  final double radius;
  final Color? fallbackColor;
  final bool isModerator;

  const UserAvatar({
    super.key,
    required this.seed,
    required this.fallbackInitial,
    this.radius = 20,
    this.fallbackColor,
    this.isModerator = false,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: isModerator
          ? AppColors.primary
          : (fallbackColor ?? AppColors.primary.withValues(alpha: 0.1)),
      child: DefaultTextStyle(
        style: TextStyle(
          color: isModerator ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
        child: Text(
          fallbackInitial,
        ),
      ),
    );
  }
}
