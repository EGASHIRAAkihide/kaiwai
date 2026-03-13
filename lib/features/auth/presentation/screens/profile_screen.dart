import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';

/// Digital ID Card — full-screen modal showing the current operative's
/// identity and a hard disconnect button.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => const ProfileScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? user?.id ?? 'UNKNOWN_OPERATIVE';
    final uid = user?.id?.substring(0, 8).toUpperCase() ?? '--------';
    final createdAt = user?.createdAt != null
        ? _formatDate(DateTime.parse(user!.createdAt))
        : '--/--/----';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top accent bar
                Container(height: 2, color: AppTheme.accent),

                // Header row with close button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        '> DIGITAL_ID',
                        style: GoogleFonts.robotoMono(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── ID Card ──────────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    color: AppTheme.accent,
                                    child: Text(
                                      'KAIWAI ID',
                                      style: GoogleFonts.rubikMonoOne(
                                        color: AppTheme.background,
                                        fontSize: 9,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    uid,
                                    style: GoogleFonts.robotoMono(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.5),
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Identified as label
                              Text(
                                'IDENTIFIED AS',
                                style: GoogleFonts.robotoMono(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                style: GoogleFonts.rubikMonoOne(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.25),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 24),
                              Container(
                                height: 1,
                                color: AppTheme.border,
                              ),
                              const SizedBox(height: 16),

                              // System specs grid
                              _SpecRow(label: 'OS', value: 'KAIWAI_v1.0'),
                              const SizedBox(height: 10),
                              _SpecRow(label: 'STATUS', value: 'ENCRYPTED'),
                              const SizedBox(height: 10),
                              _SpecRow(label: 'NETWORK', value: 'MEMBERS_ONLY'),
                              const SizedBox(height: 10),
                              _SpecRow(
                                  label: 'ENROLLED', value: createdAt),
                              const SizedBox(height: 10),
                              _SpecRow(
                                  label: 'CLEARANCE', value: 'OPERATIVE'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Disconnect button ────────────────────────────────
                        _DisconnectButton(),

                        const SizedBox(height: 24),

                        // Footer
                        Text(
                          '// UNAUTHORIZED ACCESS WILL BE LOGGED\n'
                          '// ALL ACTIVITY IS MONITORED',
                          style: GoogleFonts.robotoMono(
                            color: AppTheme.border,
                            fontSize: 9,
                            letterSpacing: 1.5,
                            height: 1.9,
                          ),
                        ),
                        const SizedBox(height: 32),
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

  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }
}

// ── Spec row ──────────────────────────────────────────────────────────────────

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              color: AppTheme.textSecondary,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Text(
          ': ',
          style: GoogleFonts.robotoMono(
            color: AppTheme.accent.withValues(alpha: 0.4),
            fontSize: 9,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.robotoMono(
              color: AppTheme.textPrimary,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Disconnect button ─────────────────────────────────────────────────────────

class _DisconnectButton extends StatefulWidget {
  @override
  State<_DisconnectButton> createState() => _DisconnectButtonState();
}

class _DisconnectButtonState extends State<_DisconnectButton> {
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await AuthRepository().signOut();
      // _AuthGate in main.dart will rebuild and show LoginScreen automatically.
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surface,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            content: Text(
              'DISCONNECT FAILED — $e',
              style: GoogleFonts.robotoMono(
                color: AppTheme.danger,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.06),
          border: Border.all(
            color: AppTheme.danger.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.danger,
                  ),
                ),
              )
            : Row(
                children: [
                  Text(
                    '[!]',
                    style: GoogleFonts.robotoMono(
                      color: AppTheme.danger.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LOGOUT / DISCONNECT',
                    style: GoogleFonts.rubikMonoOne(
                      color: AppTheme.danger,
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
