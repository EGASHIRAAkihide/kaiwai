import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';

/// Terminal-style authentication gate.
///
/// Shown when no active Supabase session exists. Offers:
///   • Google OAuth (one-tap)
///   • Magic Link (email OTP)
///
/// On successful auth, [Supabase.instance.client.auth.onAuthStateChange]
/// fires and the [_AuthGate] in [main.dart] swaps this screen for [MapScreen].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _showMagicLinkForm = false;
  bool _isLoading = false;
  bool _magicLinkSent = false;

  late final AnimationController _scanController;
  late final Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authRepo.signInWithGoogle();
    } catch (e) {
      if (mounted) _snack('GOOGLE AUTH FAILED — TRY AGAIN', AppTheme.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _snack('ENTER YOUR EMAIL ADDRESS', AppTheme.accent);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authRepo.signInWithMagicLink(email);
      if (mounted) setState(() => _magicLinkSent = true);
    } catch (e) {
      if (mounted) _snack('TRANSMISSION FAILED — CHECK EMAIL', AppTheme.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        content: Text(
          message,
          style: GoogleFonts.robotoMono(
            color: color,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Subtle scan line animation across the full screen
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) {
              final h = MediaQuery.of(context).size.height;
              return Positioned(
                top: _scanAnim.value * h,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  color: AppTheme.accent.withValues(alpha: 0.04),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // Top accent bar
                Container(height: 2, color: AppTheme.accent),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        if (_magicLinkSent)
                          _buildMagicLinkSentState()
                        else if (_showMagicLinkForm)
                          _buildMagicLinkForm()
                        else
                          _buildAuthOptions(),
                        const SizedBox(height: 48),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // System prompt line
        Row(
          children: [
            Text(
              '> ',
              style: GoogleFonts.robotoMono(
                color: AppTheme.accent,
                fontSize: 12,
              ),
            ),
            Text(
              'KAIWAI_AUTH_v1.0',
              style: GoogleFonts.robotoMono(
                color: AppTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Main title — two-line stacked
        Text(
          'IDENTIFY',
          style: GoogleFonts.rubikMonoOne(
            color: AppTheme.textPrimary,
            fontSize: 38,
            letterSpacing: 2,
            height: 1.0,
          ),
        ),
        Text(
          'YOURSELF',
          style: GoogleFonts.rubikMonoOne(
            color: AppTheme.accent,
            fontSize: 38,
            letterSpacing: 2,
            height: 1.1,
            shadows: [
              Shadow(
                color: AppTheme.accent.withValues(alpha: 0.5),
                blurRadius: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Subtitle
        Text(
          'ACCESS RESTRICTED — MEMBERS ONLY\n'
          'AUTHENTICATE TO ENTER THE NETWORK',
          style: GoogleFonts.robotoMono(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 1.5,
            height: 1.9,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 1,
          color: AppTheme.accent.withValues(alpha: 0.25),
        ),
      ],
    );
  }

  Widget _buildAuthOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// SELECT AUTH METHOD',
          style: GoogleFonts.robotoMono(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),

        // Google — filled / primary action
        _TerminalButton(
          prefix: '[G]',
          label: 'SIGN IN WITH GOOGLE',
          filled: true,
          isLoading: _isLoading,
          onTap: _isLoading ? null : _signInWithGoogle,
        ),

        const SizedBox(height: 12),

        // OR divider
        Row(
          children: [
            Expanded(child: Container(height: 1, color: AppTheme.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '//OR//',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: AppTheme.border)),
          ],
        ),

        const SizedBox(height: 12),

        // Magic link — outline / secondary action
        _TerminalButton(
          prefix: '[✉]',
          label: 'MAGIC LINK',
          filled: false,
          isLoading: false,
          onTap: () => setState(() => _showMagicLinkForm = true),
        ),

      ],
    );
  }

  Widget _buildMagicLinkForm() {
    const fieldBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppTheme.border),
      borderRadius: BorderRadius.zero,
    );
    final focusBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppTheme.accent.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.zero,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back link
        GestureDetector(
          onTap: () => setState(() => _showMagicLinkForm = false),
          child: Text(
            '< BACK',
            style: GoogleFonts.robotoMono(
              color: AppTheme.accent,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          '// ENTER OPERATIVE EMAIL',
          style: GoogleFonts.robotoMono(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: GoogleFonts.robotoMono(
            color: AppTheme.textPrimary,
            fontSize: 13,
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            labelText: 'EMAIL',
            labelStyle: GoogleFonts.robotoMono(
              color: AppTheme.textSecondary,
              fontSize: 10,
              letterSpacing: 2,
            ),
            enabledBorder: fieldBorder,
            focusedBorder: focusBorder,
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _sendMagicLink,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.3),
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.background,
                    ),
                  )
                : Text(
                    '▶  TRANSMIT LINK',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.background,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicLinkSentState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✓ LINK TRANSMITTED',
                style: GoogleFonts.rubikMonoOne(
                  color: AppTheme.accent,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: AppTheme.accent.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'CHECK YOUR INBOX.\nCLICK THE LINK TO ENTER THE NETWORK.',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  height: 1.9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() {
            _magicLinkSent = false;
            _showMagicLinkForm = false;
          }),
          child: Text(
            '< TRY ANOTHER METHOD',
            style: GoogleFonts.robotoMono(
              color: AppTheme.accent,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: AppTheme.border),
        const SizedBox(height: 16),
        Text(
          '// KAIWAI NETWORK — MEMBERS ONLY\n'
          '// UNAUTHORIZED ACCESS WILL BE LOGGED',
          style: GoogleFonts.robotoMono(
            color: AppTheme.border,
            fontSize: 9,
            letterSpacing: 1.5,
            height: 1.9,
          ),
        ),
      ],
    );
  }
}

// ── Reusable terminal-style button ───────────────────────────────────────────

class _TerminalButton extends StatelessWidget {
  const _TerminalButton({
    required this.prefix,
    required this.label,
    required this.filled,
    required this.isLoading,
    required this.onTap,
  });

  final String prefix;
  final String label;
  final bool filled;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppTheme.background : AppTheme.textPrimary;
    final borderColor = filled ? AppTheme.accent : AppTheme.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppTheme.accent : Colors.transparent,
          border: Border.all(color: borderColor),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                ),
              )
            : Row(
                children: [
                  Text(
                    prefix,
                    style: GoogleFonts.robotoMono(
                      color: filled
                          ? AppTheme.background
                          : AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.rubikMonoOne(
                      color: fg,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
