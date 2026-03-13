import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'l10n/app_l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the IANA timezone database so TimezoneUtils can resolve
  // arbitrary timezone IDs (e.g., "Asia/Tokyo", "America/New_York").
  // latest_10y contains rules for the next 10 years — smaller than latest.dart
  // (~80 KB vs ~400 KB) and sufficient for a travel app.
  tz_data.initializeTimeZones();

  await Supabase.initialize(
    url: 'https://drmpodpjjakzkftbeirh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRybXBvZHBqamFremtmdGJlaXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3NzI1NjcsImV4cCI6MjA4ODM0ODU2N30.EUn9bClj0bHPWhyPRWIi50m3e61kqnEPJzMYJCF79yQ',
  );

  runApp(const KaiwaiApp());
}

class KaiwaiApp extends StatelessWidget {
  const KaiwaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAIWAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,

      // ── Localizations ────────────────────────────────────────────────────
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,

      home: const _AuthGate(),
    );
  }
}

/// Listens to [Supabase.instance.client.auth.onAuthStateChange] and routes
/// between [LoginScreen] (no session) and [MapScreen] (active session).
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While the stream hasn't emitted yet, check the current session
        // synchronously so there's no flash of the login screen on cold start.
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session != null) return const MapScreen();
        return const LoginScreen();
      },
    );
  }
}
