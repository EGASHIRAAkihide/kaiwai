import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
/// Terminal-brutalist aesthetic — zero border-radius, monospace type.
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.accent, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 2,
              margin: const EdgeInsets.only(bottom: 16),
              color: AppTheme.border,
            ),
          ),

          // System header row
          Row(
            children: [
              Text(
                '> SPOT DETECTED',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Text(
                  '[ × ]',
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            height: 1,
            color: AppTheme.accent.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),

          // Spot name
          Text(
            spot.name.toUpperCase(),
            style: GoogleFonts.rubikMonoOne(
              color: AppTheme.accent,
              fontSize: 22,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: AppTheme.accent.withValues(alpha: 0.45),
                  blurRadius: 14,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Radius meta
          Row(
            children: [
              Text(
                'RADIUS',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '// ${spot.radiusMeters}m',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.accent.withValues(alpha: 0.7),
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          if (spot.description != null && spot.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              spot.description!,
              style: GoogleFonts.robotoMono(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 0.5,
                height: 1.7,
              ),
            ),
          ],

          const SizedBox(height: 24),
          Container(height: 1, color: AppTheme.border),
          const SizedBox(height: 16),

          // Check-in CTA — zero border-radius, full-width acid yellow
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onCheckIn,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: AppTheme.accent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.background,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '界隈に入る',
                      style: GoogleFonts.rubikMonoOne(
                        color: AppTheme.background,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown at the bottom of the map when the user enters a spot's radius.
///
/// Extracted as a public widget so it can be widget-tested independently of
/// [MapScreen].  The map uses this widget directly.
class ProximityBanner extends StatelessWidget {
  const ProximityBanner({
    super.key,
    required this.spot,
    required this.distanceMeters,
    required this.onCheckIn,
  });

  final Spot spot;
  final int distanceMeters;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.accent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withOpacity(0.15),
              border: Border.all(color: AppTheme.accent, width: 1.5),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 14),
          // Spot info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spot.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${distanceMeters}m 以内',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // CTA
          FilledButton(
            onPressed: onCheckIn,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.background,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            child: const Text('界隈に入る'),
          ),
        ],
      ),
    );
  }
}
