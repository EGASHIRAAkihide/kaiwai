import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth calls for sign-in, sign-out, and session access.
class AuthRepository {
  final _auth = Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;
  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Initiates Google OAuth sign-in.
  ///
  /// On mobile, the redirect URL must match the custom URI scheme registered
  /// in the platform project (e.g. `io.supabase.kaiwai://login-callback`).
  Future<void> signInWithGoogle() async {
    debugPrint('[AuthRepository] signInWithGoogle →');
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.kaiwai://login-callback',
    );
  }

  /// Sends a magic-link email to [email].
  ///
  /// The user taps the link in their inbox; Supabase redirects back to the app
  /// and the session is established via the deep link handler.
  Future<void> signInWithMagicLink(String email) async {
    debugPrint('[AuthRepository] signInWithMagicLink → $email');
    await _auth.signInWithOtp(
      email: email,
      emailRedirectTo: kIsWeb ? null : 'io.supabase.kaiwai://login-callback',
    );
  }

  Future<void> signOut() async {
    debugPrint('[AuthRepository] signOut →');
    await _auth.signOut();
  }
}
