import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class StatCard extends StatelessWidget {
  const StatCard(this.icon, this.value, this.label, {super.key});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          ],
        ),
      );
}