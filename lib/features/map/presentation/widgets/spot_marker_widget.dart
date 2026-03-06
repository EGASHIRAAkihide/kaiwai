import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/spot.dart';

/// A custom map marker for a KAIWAI spot.
/// Animates between selected/unselected states with a glow effect.
class SpotMarkerWidget extends StatelessWidget {
  const SpotMarkerWidget({
    super.key,
    required this.spot,
    required this.isSelected,
    required this.onTap,
  });

  final Spot spot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: isSelected ? 56 : 44,
        height: isSelected ? 56 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppTheme.accent : AppTheme.surface,
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.accentDim,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.bolt_rounded,
            color: isSelected ? AppTheme.background : AppTheme.accent,
            size: isSelected ? 28 : 22,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet content shown when a spot marker is tapped.
class SpotInfoSheet extends StatelessWidget {
  const SpotInfoSheet({
    super.key,
    required this.spot,
    required this.onCheckIn,
    required this.onClose,
  });

  final Spot spot;
  final VoidCallback onCheckIn;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header row
          Row(
            children: [
              // Spot icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentDim, width: 1),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppTheme.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Name and radius
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${spot.radiusMeters}m radius',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),

              // Close button
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          if (spot.description != null && spot.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 16),
            Text(spot.description!, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: 24),

          // Check-in button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCheckIn,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('界隈に入る'),
            ),
          ),
        ],
      ),
    );
  }
}
