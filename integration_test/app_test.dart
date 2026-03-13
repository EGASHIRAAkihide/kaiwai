/// KAIWAI v1.0 — Integration Test Skeleton (E2E Smoke Tests)
///
/// Run on a real device or emulator:
///   flutter test integration_test/app_test.dart
///
/// These tests require:
///   - A connected device / emulator with location permissions granted.
///   - Valid Supabase credentials (already embedded in main.dart).
///
/// They are intentionally NOT run by plain `flutter test` (unit/widget suite).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kaiwai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Test — App Launch', () {
    testWidgets('App launches and renders initial screen', (tester) async {
      // ── Action: launch the full app ───────────────────────────────────────
      app.main();

      // Pump a fixed duration instead of pumpAndSettle to avoid timing out
      // on continuously-animating widgets (FlutterMap tile layer) or
      // long-running async operations (Supabase auth check, GPS).
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));

      // ── Branch: Auth screen or Map screen ─────────────────────────────────
      // Depending on session state the app may land on the Auth screen
      // (shows "SIGN IN WITH GOOGLE") or directly on the Map screen.
      final onAuthScreen =
          find.textContaining('SIGN IN').evaluate().isNotEmpty ||
          find.textContaining('Sign in').evaluate().isNotEmpty;

      if (onAuthScreen) {
        // Auth screen is a valid initial state — just confirm the UI rendered.
        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: 'Auth screen must contain at least one Scaffold',
        );
      } else {
        // ── Map screen verifications ───────────────────────────────────────

        // The map renders inside a Stack that is always present on MapScreen.
        expect(
          find.byType(Stack),
          findsWidgets,
          reason: 'Map screen must contain a Stack with map layers',
        );

        // The [ ID ] chip is visible in the top-right overlay.
        expect(
          find.text('[ ID ]'),
          findsOneWidget,
          reason: '[ ID ] identity chip must be visible in the top overlay',
        );
      }
    });
  });
}
