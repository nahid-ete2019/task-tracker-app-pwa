import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;

  const AppAvatar({super.key, this.imageUrl, required this.initials, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(imageUrl!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: radius * 0.7),
      ),
    );
  }
}
