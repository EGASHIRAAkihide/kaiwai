import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/spot_repository.dart';

/// Brutalist "Create New Kaiwai" screen.
///
/// Pre-fills GPS from [initialLatitude] / [initialLongitude] (passed in from
/// the map screen). The user sets a name, picks a radius, and optionally adds
/// a description. On submit the form calls [SpotRepository.createSpot] via the
/// `create_spot` Supabase RPC and pops with the new spot UUID on success.
class CreateSpotScreen extends StatefulWidget {
  const CreateSpotScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  final double initialLatitude;
  final double initialLongitude;

  @override
  State<CreateSpotScreen> createState() => _CreateSpotScreenState();
}

class _CreateSpotScreenState extends State<CreateSpotScreen> {
  static const _radiusOptions = [50, 100, 200, 500];

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _spotRepo = SpotRepository();

  int _selectedRadius = 100;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final newId = await _spotRepo.createSpot(
        name: _nameCtrl.text.trim(),
        latitude: widget.initialLatitude,
        longitude: widget.initialLongitude,
        radiusMeters: _selectedRadius,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(newId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          content: Text(
            'FAILED — ${e.toString().toUpperCase()}',
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '+ KAIWAI',
          style: GoogleFonts.robotoMono(
            color: AppTheme.accent,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // GPS coordinates — read-only display
            _SectionLabel('GPS COORDINATES', locale),
            const SizedBox(height: 8),
            _CoordRow(
              label: 'LAT',
              value: widget.initialLatitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 4),
            _CoordRow(
              label: 'LNG',
              value: widget.initialLongitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 28),

            // Spot name
            _SectionLabel('SPOT NAME', locale),
            const SizedBox(height: 8),
            _KaiwaiTextField(
              controller: _nameCtrl,
              hintText: '駒沢公園ランナー界隈',
              maxLength: 60,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'NAME IS REQUIRED';
                if (v.trim().length < 2) return 'TOO SHORT';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Radius selector
            _SectionLabel('RADIUS', locale),
            const SizedBox(height: 8),
            _RadiusSelector(
              options: _radiusOptions,
              selected: _selectedRadius,
              onChanged: (r) => setState(() => _selectedRadius = r),
            ),
            const SizedBox(height: 28),

            // Description (optional)
            _SectionLabel('DESCRIPTION  (OPTIONAL)', locale),
            const SizedBox(height: 8),
            _KaiwaiTextField(
              controller: _descCtrl,
              hintText: 'Describe the vibe...',
              maxLength: 200,
              maxLines: 4,
            ),
            const SizedBox(height: 40),

            // Submit button
            _SubmitButton(
              isSubmitting: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.locale);
  final String text;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.contentTitleStyle(
        locale,
        fontSize: 11,
        color: AppTheme.textSecondary,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label  ',
          style: GoogleFonts.robotoMono(
            color: AppTheme.textSecondary,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            color: AppTheme.accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _KaiwaiTextField extends StatelessWidget {
  const _KaiwaiTextField({
    required this.controller,
    required this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.robotoMono(
        color: AppTheme.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.robotoMono(
          color: AppTheme.textSecondary.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        counterStyle: GoogleFonts.robotoMono(
          color: AppTheme.textSecondary,
          fontSize: 10,
        ),
        filled: true,
        fillColor: AppTheme.surface,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        errorStyle: GoogleFonts.robotoMono(
          color: AppTheme.danger,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  const _RadiusSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((r) {
        final isSelected = r == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(r),
            child: Container(
              margin: EdgeInsets.only(right: r != options.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent : AppTheme.surface,
                border: Border.all(
                  color: isSelected ? AppTheme.accent : AppTheme.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${r}m',
                style: GoogleFonts.robotoMono(
                  color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting, required this.onPressed});
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        color: isSubmitting ? AppTheme.accentDim : AppTheme.accent,
        alignment: Alignment.center,
        child: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppTheme.background,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'CREATE KAIWAI',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.background,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}
