import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/map/presentation/screens/map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // url: const String.fromEnvironment('SUPABASE_URL'),
    // anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    // Alternatively, hard-code during development:
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
      title: '界隈',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MapScreen(),
    );
  }
}
