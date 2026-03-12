import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({
    super.key,
    required this.title,
    required this.body,
    required this.isPremium,
    this.cityCode,
    this.lat,
    this.lng,
  });

  final String title;
  final String body;
  final bool isPremium;
  final String? cityCode;
  final double? lat;
  final double? lng;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glitchCtrl;

  @override
  void initState() {
    super.initState();
    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _glitchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: _GlitchBackButton(controller: _glitchCtrl),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.accent.withValues(alpha: 0.25),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (widget.cityCode != null && widget.cityCode!.isNotEmpty)
            _CityCodeWatermark(code: widget.cityCode!),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isPremium) ...[
                  const _LocationVerifiedBadge(),
                  const SizedBox(height: 20),
                ],
                Text(
                  widget.title,
                  style: GoogleFonts.rubikMonoOne(
                    fontSize: 22,
                    color: AppTheme.accent,
                    letterSpacing: 1.2,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 2, width: 40, color: AppTheme.accent),
                const SizedBox(height: 32),
                _TypewriterText(
                  text: widget.body.isNotEmpty
                      ? widget.body
                      : '// NO CONTENT AVAILABLE\n// CHECK BACK LATER',
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    color: AppTheme.textPrimary.withValues(alpha: 0.88),
                    letterSpacing: 0.3,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                _NoteMetadata(lat: widget.lat, lng: widget.lng),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typewriter Text ───────────────────────────────────────────────────────────

class _TypewriterText extends StatefulWidget {
  const _TypewriterText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _visibleChars = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  void _startTypewriter() {
    // ~20ms per char gives a fast but visible transmission feel
    _timer = Timer.periodic(const Duration(milliseconds: 18), (_) {
      if (!mounted) return;
      if (_visibleChars >= widget.text.length) {
        _timer?.cancel();
        return;
      }
      setState(() => _visibleChars++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _visibleChars),
      style: widget.style,
    );
  }
}

// ── Note Metadata Footer ──────────────────────────────────────────────────────

class _NoteMetadata extends StatelessWidget {
  const _NoteMetadata({this.lat, this.lng});

  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    final latStr = lat != null ? lat!.toStringAsFixed(5) : '???.?????';
    final lngStr = lng != null ? lng!.toStringAsFixed(5) : '???.?????';
    final ts = DateTime.now().toUtc();
    final tsStr =
        '${ts.year}-${_z(ts.month)}-${_z(ts.day)} ${_z(ts.hour)}:${_z(ts.minute)} UTC';

    final labelStyle = GoogleFonts.robotoMono(
      fontSize: 9,
      color: AppTheme.textSecondary,
      letterSpacing: 1.2,
    );
    final valueStyle = GoogleFonts.robotoMono(
      fontSize: 9,
      color: AppTheme.accent.withValues(alpha: 0.7),
      letterSpacing: 1.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: AppTheme.border,
          margin: const EdgeInsets.only(bottom: 12),
        ),
        _MetaRow(
          label: 'LAT/LNG',
          value: '$latStr / $lngStr',
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        const SizedBox(height: 6),
        _MetaRow(
          label: 'TIMESTAMP',
          value: tsStr,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        const SizedBox(height: 6),
        _MetaRow(
          label: 'ACCESS',
          value: 'AES-256 // ENCRYPTED CHANNEL',
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
      ],
    );
  }

  String _z(int n) => n.toString().padLeft(2, '0');
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: labelStyle),
        ),
        Text('// ', style: labelStyle),
        Expanded(child: Text(value, style: valueStyle)),
      ],
    );
  }
}

// ── Glitch Back Button ────────────────────────────────────────────────────────

class _GlitchBackButton extends StatelessWidget {
  const _GlitchBackButton({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final frame = (controller.value * 20).floor();
        final glitch =
            controller.isAnimating && (frame % 4 == 0 || frame % 6 == 1);

        return IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: glitch
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: const Offset(2.5, 0),
                      child: Icon(
                        Icons.close_rounded,
                        color:
                            const Color(0xFF00FFFF).withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-2.5, 0),
                      child: Icon(
                        Icons.close_rounded,
                        color:
                            const Color(0xFFFF0080).withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                    const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textPrimary,
                      size: 22,
                    ),
                  ],
                )
              : const Icon(
                  Icons.close_rounded,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
        );
      },
    );
  }
}

// ── City Code Watermark ───────────────────────────────────────────────────────

class _CityCodeWatermark extends StatelessWidget {
  const _CityCodeWatermark({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            code,
            style: GoogleFonts.rubikMonoOne(
              fontSize: 140,
              color: AppTheme.textPrimary.withValues(alpha: 0.025),
              letterSpacing: 8,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Location Verified Badge ───────────────────────────────────────────────────

class _LocationVerifiedBadge extends StatelessWidget {
  const _LocationVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppTheme.accent,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            'LOCATION VERIFIED',
            style: GoogleFonts.rubikMonoOne(
              fontSize: 10,
              color: AppTheme.accent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
