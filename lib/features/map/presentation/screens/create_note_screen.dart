import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/screens/login_screen.dart';
import '../../data/repositories/content_repository.dart';
import '../../domain/models/spot.dart';

/// Terminal-style note editor for creating a 界隈ノート attached to [spot].
///
/// On save, inserts a public [Content] row into the `contents` table via
/// [ContentRepository.createContent]. Pops with `true` on success so the
/// caller can refresh its note list.
///
/// Supabase auth is required — the current user's ID is used as `author_id`.
class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key, required this.spot});

  final Spot spot;

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _contentRepo = ContentRepository();

  bool _isSaving = false;
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) {
        if (mounted) setState(() => _cursorVisible = !_cursorVisible);
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _cursorTimer?.cancel();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _transmit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _snack('TRANSMISSION INCOMPLETE — ADD SUBJECT AND BODY', AppTheme.accent);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _snack('AUTH REQUIRED — LOGIN TO TRANSMIT', AppTheme.danger);
      if (mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _contentRepo.createContent(
        spotId: widget.spot.id,
        authorId: user.id,
        title: title.toUpperCase(),
        body: body,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final isRls = e.toString().contains('42501') ||
            e.toString().toLowerCase().contains('permission denied') ||
            e.toString().toLowerCase().contains('row-level security');
        _snack(
          isRls
              ? 'ACCESS DENIED — CHECK RLS POLICIES'
              : 'TRANSMISSION FAILED',
          AppTheme.danger,
        );
      }
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSpotHeader(),
          Expanded(child: _buildEditor()),
          _buildFooter(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: RichText(
        text: TextSpan(
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            letterSpacing: 2,
            color: AppTheme.textSecondary,
          ),
          children: [
            const TextSpan(text: '[ '),
            TextSpan(
              text: 'NEW TRANSMISSION',
              style: GoogleFonts.robotoMono(
                color: AppTheme.accent,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const TextSpan(text: ' ]'),
          ],
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.accent.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildSpotHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text(
            'SPOT // ',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              widget.spot.name.toUpperCase(),
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                color: AppTheme.accent,
                letterSpacing: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'PUBLIC',
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final monoStyle = GoogleFonts.robotoMono(
      fontSize: 13,
      color: AppTheme.textPrimary,
      letterSpacing: 0.5,
      height: 1.6,
    );
    final labelStyle = GoogleFonts.robotoMono(
      fontSize: 10,
      color: AppTheme.textSecondary,
      letterSpacing: 2,
    );
    const fieldBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppTheme.border),
      borderRadius: BorderRadius.zero,
    );
    final focusBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppTheme.accent.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.zero,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blinking prompt line
          Row(
            children: [
              Text(
                '> ',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: AppTheme.accent,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'COMPOSING NOTE',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 4),
              Opacity(
                opacity: _cursorVisible ? 1.0 : 0.0,
                child: Text(
                  '█',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subject / title field
          TextField(
            controller: _titleController,
            style: monoStyle.copyWith(
              color: AppTheme.accent,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'SUBJECT',
              labelStyle: labelStyle,
              enabledBorder: fieldBorder,
              focusedBorder: focusBorder,
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.all(12),
              counterStyle: GoogleFonts.robotoMono(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
            maxLines: 1,
            maxLength: 80,
          ),
          const SizedBox(height: 16),

          // Body field
          TextField(
            controller: _bodyController,
            style: monoStyle,
            decoration: InputDecoration(
              labelText: 'TRANSMISSION BODY',
              labelStyle: labelStyle,
              alignLabelWithHint: true,
              enabledBorder: fieldBorder,
              focusedBorder: focusBorder,
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.all(12),
            ),
            minLines: 14,
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _isSaving ? null : _transmit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accent,
            disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.3),
            foregroundColor: AppTheme.background,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.background,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'TRANSMITTING...',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppTheme.background,
                      ),
                    ),
                  ],
                )
              : Text(
                  '▶  TRANSMIT',
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.background,
                  ),
                ),
        ),
      ),
    );
  }
}
