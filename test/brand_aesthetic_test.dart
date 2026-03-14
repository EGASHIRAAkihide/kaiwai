/// Widget tests that guard KAIWAI's "Brutalist" brand identity.
///
/// These tests verify:
///   - No rounded corners (BorderRadius.zero / null) on key containers.
///   - Spot titles use the RubikMonoOne typeface.
///   - Primary CTA buttons carry the Acid Yellow accent (#E2FF4F).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kaiwai/core/theme/app_theme.dart';
import 'package:kaiwai/features/map/domain/models/spot.dart';
import 'package:kaiwai/features/map/presentation/widgets/spot_marker_widget.dart';

// ── Test fixture ──────────────────────────────────────────────────────────────

const _testSpot = Spot(
  id: 'brand-test-spot',
  name: 'Shibuya',
  latitude: 35.6595,
  longitude: 139.7004,
  radiusMeters: 300,
  description: 'Urban jungle test fixture.',
);

/// Wraps [child] in a minimal themed app so brand tokens resolve correctly.
Widget _themed(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    );

// ── Entry point ───────────────────────────────────────────────────────────────

void main() {
  // ── SpotInfoSheet ───────────────────────────────────────────────────────────

  group('SpotInfoSheet — brand identity', () {
    setUp(() {
      // Prevent google_fonts from hitting the network during tests.
      GoogleFonts.config.allowRuntimeFetching = false;
    });

    testWidgets('root container has no border radius (flat/brutalist)',
        (tester) async {
      await tester.pumpWidget(
        _themed(
          SpotInfoSheet(
            spot: _testSpot,
            onCheckIn: () {},
            onClose: () {},
          ),
        ),
      );

      // The outermost Container of SpotInfoSheet uses a BoxDecoration with no
      // borderRadius — confirming the brutalist zero-radius constraint.
      final allContainers =
          tester.widgetList<Container>(find.byType(Container)).toList();
      expect(allContainers, isNotEmpty);

      final rootContainer = allContainers.first;
      final deco = rootContainer.decoration as BoxDecoration?;
      // null borderRadius is visually equivalent to BorderRadius.zero.
      expect(
        deco?.borderRadius,
        isNull,
        reason:
            'SpotInfoSheet root container must have no border radius (brutalist)',
      );
    });

    testWidgets('spot name title uses RubikMonoOne typeface', (tester) async {
      await tester.pumpWidget(
        _themed(
          SpotInfoSheet(
            spot: _testSpot,
            onCheckIn: () {},
            onClose: () {},
          ),
        ),
      );

      // The spot name is rendered as spot.name.toUpperCase()
      final nameFinder = find.text(_testSpot.name.toUpperCase());
      expect(nameFinder, findsOneWidget,
          reason: 'SpotInfoSheet must display the spot name in upper case');

      final nameText = tester.widget<Text>(nameFinder);
      final fontFamily = nameText.style?.fontFamily ?? '';
      expect(
        fontFamily.toLowerCase(),
        contains('rubikmonoone'),
        reason: 'Spot name must be rendered in RubikMonoOne (brand typeface)',
      );
    });

    testWidgets('action button container uses acid-yellow accent (#E2FF4F)',
        (tester) async {
      await tester.pumpWidget(
        _themed(
          SpotInfoSheet(
            spot: _testSpot,
            onCheckIn: () {},
            onClose: () {},
          ),
        ),
      );

      // The CTA is a Container with color: AppTheme.accent (no BoxDecoration).
      final accentContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color == AppTheme.accent)
          .toList();

      expect(
        accentContainers,
        isNotEmpty,
        reason:
            'SpotInfoSheet CTA container must use acid-yellow accent #E2FF4F',
      );
    });
  });

  // ── ProximityBanner ─────────────────────────────────────────────────────────

  group('ProximityBanner — brand identity', () {
    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
    });

    testWidgets('root container has no border radius (flat/brutalist)',
        (tester) async {
      await tester.pumpWidget(
        _themed(
          ProximityBanner(
            spot: _testSpot,
            distanceMeters: 150,
            onCheckIn: () {},
          ),
        ),
      );

      final allContainers =
          tester.widgetList<Container>(find.byType(Container)).toList();
      expect(allContainers, isNotEmpty);

      final rootContainer = allContainers.first;
      final deco = rootContainer.decoration as BoxDecoration?;
      expect(
        deco?.borderRadius,
        isNull,
        reason:
            'ProximityBanner root container must have no border radius (brutalist)',
      );
    });

    testWidgets('CTA FilledButton uses acid-yellow background (#E2FF4F)',
        (tester) async {
      await tester.pumpWidget(
        _themed(
          ProximityBanner(
            spot: _testSpot,
            distanceMeters: 150,
            onCheckIn: () {},
          ),
        ),
      );

      final buttons =
          tester.widgetList<FilledButton>(find.byType(FilledButton)).toList();
      expect(buttons, isNotEmpty,
          reason: 'ProximityBanner must contain a FilledButton CTA');

      final btn = buttons.first;
      // Resolve the background color with no active material states.
      final bgColor =
          btn.style?.backgroundColor?.resolve(const <WidgetState>{});
      expect(
        bgColor,
        equals(AppTheme.accent),
        reason: 'ProximityBanner CTA must use acid-yellow accent #E2FF4F',
      );
    });

    testWidgets('CTA button has zero border radius (brutalist shape)',
        (tester) async {
      await tester.pumpWidget(
        _themed(
          ProximityBanner(
            spot: _testSpot,
            distanceMeters: 150,
            onCheckIn: () {},
          ),
        ),
      );

      final buttons =
          tester.widgetList<FilledButton>(find.byType(FilledButton)).toList();
      expect(buttons, isNotEmpty);

      final btn = buttons.first;
      final shape = btn.style?.shape
          ?.resolve(const <WidgetState>{}) as RoundedRectangleBorder?;
      expect(
        shape?.borderRadius,
        equals(BorderRadius.zero),
        reason: 'ProximityBanner CTA must have zero border radius',
      );
    });
  });
}
