import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MacroProgressCard extends StatelessWidget {
  final String title;
  final double consumed;
  final double target;
  final String unit;
  final Color color;

  const MacroProgressCard({
    Key? key,
    required this.title,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate percentage of target reached
    final percentage = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingSmall),
            
            // Progress bar
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            
            const SizedBox(height: AppTheme.spacingSmall),
            
            // Progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${consumed.toInt()} $unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
                Text(
                  '${target.toInt()} $unit',
                  style: const TextStyle(
                    color: AppTheme.textColorSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingSmall),
            
            // Percentage text
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 