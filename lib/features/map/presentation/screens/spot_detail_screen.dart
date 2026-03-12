import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_utils.dart';
import '../../../../l10n/app_l10n.dart';
import '../../data/repositories/content_repository.dart';
import '../../domain/models/content.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/spot.dart';
import 'note_detail_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

TextStyle _streetFont({
  double size = 14,
  Color color = AppTheme.textPrimary,
  double spacing = 1.5,
}) =>
    GoogleFonts.rubikMonoOne(
      fontSize: size,
      color: color,
      letterSpacing: spacing,
    );

String _tallyMark(int rank) => switch (rank) {
      1 => 'I',
      2 => 'II',
      3 => 'III',
      _ => '#$rank',
    };

// ── Main Screen ───────────────────────────────────────────────────────────────

class SpotDetailScreen extends StatefulWidget {
  const SpotDetailScreen({super.key, required this.spot});

  final Spot spot;

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _glitchController;
  final _contentRepo = ContentRepository();

  List<Content>? _contents;
  List<LeaderboardEntry>? _leaderboard;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _contentRepo.fetchContents(widget.spot.id),
        _contentRepo.getLeaderboard(widget.spot.id),
      ]);
      if (!mounted) return;
      setState(() {
        _contents = results[0] as List<Content>;
        _leaderboard = results[1] as List<LeaderboardEntry>;
      });
    } catch (_) {
      // TODO(auth): remove dev fallback before release — real data load blocked
      //             by RLS until the user is authenticated.
      if (!mounted) return;
      setState(() {
        _contents = _devContents;
        _leaderboard = _devLeaderboard;
      });
    }
  }

  // ── Dev dummy data (visible before auth is wired up) ──────────────────────

  static final _devContents = [
    const Content(
      id: 'dev-1',
      spotId: 'dev',
      authorId: 'dev',
      title: 'HYROX PREP // WEEK 4 PROTOCOL',
      bodyJson: {
        'text':
            'SESSION 01 — BASE BUILD\n'
            '> 2km row @ 2:05/500m\n'
            '> 50x wall ball (9kg)\n'
            '> 1km ski erg\n'
            '> rest 90s, repeat x3\n\n'
            'SESSION 02 — TRANSITION DRILLS\n'
            '> sled push 50m + burpee broad jump 20m\n'
            '> farmers carry 200m (24kg each)\n'
            '> repeat x4 no rest between stations\n\n'
            '// NOTES: HR cap at 165bpm. Kill pace if\n'
            '// you blow past that. Recovery is training.',
      },
      isPremium: false,
      price: 0,
    ),
    const Content(
      id: 'dev-2',
      spotId: 'dev',
      authorId: 'dev',
      title: 'THRESHOLD INTERVALS — SECRET PROGRAMME',
      bodyJson: {
        'text':
            'BLOCK A — LACTATE THRESHOLD\n'
            '> 6x1000m @ 95% max HR\n'
            '> 2min passive recovery\n'
            '> target pace: sub 4:10/km\n\n'
            'BLOCK B — VO2 OVERREACH\n'
            '> 10x400m @ 105% vVO2max\n'
            '> 90s jog recovery\n'
            '> do NOT check watch mid-rep\n\n'
            'BLOCK C — NEURAL ACTIVATION\n'
            '> 5x50m all-out sprint\n'
            '> walk back full recovery\n\n'
            '// ACCESS LEVEL: VERIFIED MEMBER\n'
            '// DISTRIBUTE TO OUTSIDERS = BANNED',
      },
      isPremium: true,
      price: 800,
    ),
    const Content(
      id: 'dev-3',
      spotId: 'dev',
      authorId: 'dev',
      title: 'ROOFTOP SESSION NOTES (OPEN)',
      bodyJson: {
        'text':
            'DATE: EVERY SATURDAY 06:00\n'
            'LOCATION: LEVEL 12 CARPARK\n'
            'BRING: KETTLEBELL 16-24kg, JUMP ROPE\n\n'
            'FORMAT:\n'
            '> 5min amrap warm-up\n'
            '> 4 rounds —\n'
            '   100x skip\n'
            '   20x kb swing\n'
            '   10x kb clean & press each side\n'
            '   400m stairwell run\n'
            '> cooldown + mobility 10min\n\n'
            '// OPEN TO ALL. NO EGOS.\n'
            '// FIRST TIME? SHOW UP.',
      },
      isPremium: false,
      price: 0,
    ),
    const Content(
      id: 'dev-4',
      spotId: 'dev',
      authorId: 'dev',
      title: 'ELITE SLED PUSH MECHANICS',
      bodyJson: {
        'text':
            'STANCE: shoulder-width, slight hip hinge\n'
            'GRIP: overhand, elbows locked out\n'
            'DRIVE ANGLE: 30-45deg from horizontal\n\n'
            'PHASE 1 — INITIAL DRIVE\n'
            '> explosive hip extension\n'
            '> screw feet into ground\n'
            '> inhale at start, exhale on stride\n\n'
            'PHASE 2 — STEADY STATE\n'
            '> maintain constant pressure\n'
            '> short, rapid steps (< 0.4s ground contact)\n'
            '> DO NOT let hips rise above shoulders\n\n'
            'COMMON FAULTS:\n'
            '> pulling with arms = energy leak\n'
            '> looking down = kills posture\n'
            '> tempo drops after 20m = undertrained\n\n'
            '// PROPRIETARY. KAIWAI ELITE ONLY.',
      },
      isPremium: true,
      price: 1200,
    ),
  ];

  static final _devLeaderboard = [
    const LeaderboardEntry(
      userId: 'u1',
      username: 'TENZING_ULTRA',
      checkInCount: 47,
    ),
    const LeaderboardEntry(
      userId: 'u2',
      username: 'SAKURA_GRIND',
      checkInCount: 39,
    ),
    const LeaderboardEntry(
      userId: 'u3',
      username: 'NEON_MONK',
      checkInCount: 31,
    ),
    const LeaderboardEntry(
      userId: 'u4',
      username: 'ASPHALT_OX',
      checkInCount: 22,
    ),
    const LeaderboardEntry(
      userId: 'u5',
      username: 'FLUX_RIDER',
      checkInCount: 14,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _error != null ? _buildError() : _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: const _ConcreteTextureBg(),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: _GlitchText(
                  text: widget.spot.name.toUpperCase(),
                  controller: _glitchController,
                  style: _streetFont(size: 16, spacing: 2.0),
                ),
              ),
              if (widget.spot.countryCode != null ||
                  widget.spot.cityName != null) ...[
                const SizedBox(width: 8),
                _GlobalBadge(spot: widget.spot),
              ],
            ],
          ),
          _SpotMetaLine(spot: widget.spot),
        ],
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(49),
        child: Column(
          children: [
            Container(
              height: 1,
              color: AppTheme.accent.withValues(alpha: 0.35),
            ),
            TabBar(
              controller: _tabController,
              indicator: const _SprayIndicatorDecoration(),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.rubikMonoOne(
                fontSize: 11,
                letterSpacing: 1.5,
              ),
              unselectedLabelStyle: GoogleFonts.rubikMonoOne(
                fontSize: 11,
                letterSpacing: 1.5,
              ),
              tabs: [
                Tab(text: AppL10n.of(context).notesTab),
                Tab(text: AppL10n.of(context).rankingTab),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_contents == null || _leaderboard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              AppL10n.of(context).loading,
              style: _streetFont(
                size: 11,
                color: AppTheme.textSecondary,
                spacing: 3,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _NotesTab(
          contents: _contents!,
          cityCode: TimezoneUtils.cityCode(widget.spot.cityName),
        ),
        _RankingTab(leaderboard: _leaderboard!),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              AppL10n.of(context).dataLoadFailed,
              style: _streetFont(size: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.background,
              ),
              child: Text(
                AppL10n.of(context).retry,
                style: _streetFont(
                  size: 12,
                  color: AppTheme.background,
                  spacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glitch Text ───────────────────────────────────────────────────────────────

class _GlitchText extends StatelessWidget {
  const _GlitchText({
    required this.text,
    required this.controller,
    required this.style,
  });

  final String text;
  final AnimationController controller;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final frame = (t * 24).floor();
        final isGlitching =
            controller.isAnimating && (frame % 5 == 0 || frame % 7 == 1);

        if (!isGlitching) return Text(text, style: style);

        return Stack(
          children: [
            Transform.translate(
              offset: const Offset(3, 0),
              child: Text(
                text,
                style: style.copyWith(
                  color: const Color(0xFF00FFFF).withValues(alpha: 0.55),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-3, 0),
              child: Text(
                text,
                style: style.copyWith(
                  color: const Color(0xFFFF0080).withValues(alpha: 0.55),
                ),
              ),
            ),
            Text(text, style: style),
          ],
        );
      },
    );
  }
}

// ── Concrete Texture Background ───────────────────────────────────────────────

class _ConcreteTextureBg extends StatelessWidget {
  const _ConcreteTextureBg();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ConcreteTexturePainter());
  }
}

class _ConcreteTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF202020)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const spacing = 14.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Spray-Painted Tab Indicator ───────────────────────────────────────────────

class _SprayIndicatorDecoration extends Decoration {
  const _SprayIndicatorDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _SprayBoxPainter();
}

class _SprayBoxPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    if (config.size == null) return;
    final w = config.size!.width;
    final h = config.size!.height;
    final rng = math.Random(42);

    final linePaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final baseY = offset.dy + h - 2.5;

    final path = Path()
      ..moveTo(offset.dx + 2, baseY + (rng.nextDouble() - 0.5) * 2);
    for (double x = offset.dx + 5; x <= offset.dx + w - 2; x += 3) {
      path.lineTo(x, baseY + (rng.nextDouble() - 0.5) * 2.5);
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < 8; i++) {
      final dx = offset.dx + rng.nextDouble() * w;
      final dy = baseY + (rng.nextDouble() - 0.5) * 6;
      canvas.drawCircle(Offset(dx, dy), rng.nextDouble() * 1.5 + 0.5, dotPaint);
    }
  }
}

// ── Torn Corner Clipper ───────────────────────────────────────────────────────

class _TornCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const t = 10.0;
    return Path()
      ..moveTo(t + 3, 0)
      ..lineTo(size.width - t + 1, 0)
      ..lineTo(size.width, t - 2)
      ..lineTo(size.width, size.height - t + 3)
      ..lineTo(size.width - t - 1, size.height)
      ..lineTo(t, size.height)
      ..lineTo(0, size.height - t + 2)
      ..lineTo(0, t)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

// ── Neon Flicker Widget ───────────────────────────────────────────────────────

class _NeonFlicker extends StatefulWidget {
  const _NeonFlicker({required this.child});

  final Widget child;

  @override
  State<_NeonFlicker> createState() => _NeonFlickerState();
}

class _NeonFlickerState extends State<_NeonFlicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 0.50), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.50, end: 1.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.96), weight: 20),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
      child: widget.child,
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.contents, required this.cityCode});

  final List<Content> contents;
  final String cityCode;

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article_outlined,
                color: AppTheme.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              AppL10n.of(context).noContentYet,
              style: _streetFont(size: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          _ContentCard(content: contents[i], cityCode: cityCode),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.content, required this.cityCode});

  final Content content;
  final String cityCode;

  String _extractBody() {
    final json = content.bodyJson;
    if (json == null) return '';
    if (json['text'] is String) return json['text'] as String;
    return json.values.whereType<String>().join('\n\n');
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteDetailScreen(
          title: content.title,
          body: _extractBody(),
          isPremium: content.isPremium,
          cityCode: cityCode.isNotEmpty ? cityCode : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: ClipPath(
        clipper: _TornCornerClipper(),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          content.title,
                          style: _streetFont(size: 14, spacing: 1.0),
                        ),
                      ),
                      if (content.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppTheme.accentDim.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '¥${content.price}',
                            style: _streetFont(
                              size: 10,
                              color: AppTheme.accent,
                              spacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!content.isPremium) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppL10n.of(context).tapToRead,
                      style: _streetFont(
                        size: 10,
                        color: AppTheme.textSecondary,
                        spacing: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (content.isPremium) const _BarricadeTapeOverlay(),
          ],
        ),
      ),
    );
  }
}

// ── Barricade Tape Overlay ────────────────────────────────────────────────────

class _BarricadeTapeOverlay extends StatelessWidget {
  const _BarricadeTapeOverlay();

  @override
  Widget build(BuildContext context) {
    const tapeText =
        ' /// WARNING /// PRIVATE /// WARNING /// PRIVATE /// WARNING ///';
    return Positioned.fill(
      child: Container(
        color: AppTheme.background.withValues(alpha: 0.88),
        child: ClipRect(
          child: Align(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.rotate(
                angle: -0.42,
                child: SizedBox(
                  width: 600,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      8,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          tapeText,
                          style: GoogleFonts.rubikMonoOne(
                            color: i.isEven
                                ? AppTheme.accent
                                : AppTheme.accent.withValues(alpha: 0.55),
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ranking Tab ───────────────────────────────────────────────────────────────

class _RankingTab extends StatelessWidget {
  const _RankingTab({required this.leaderboard});

  final List<LeaderboardEntry> leaderboard;

  @override
  Widget build(BuildContext context) {
    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard_rounded,
                color: AppTheme.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              AppL10n.of(context).noCheckInsYet,
              style: _streetFont(size: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _RankingRow(entry: leaderboard[i], rank: i + 1),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.rank});

  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColor = isTop3 ? AppTheme.accent : AppTheme.textSecondary;

    Widget row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isTop3
            ? AppTheme.surface
            : AppTheme.surface.withValues(alpha: 0.6),
        border: Border.all(
          color: isTop3
              ? AppTheme.accent.withValues(alpha: 0.3)
              : AppTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _tallyMark(rank),
              style: GoogleFonts.rubikMonoOne(
                color: rankColor,
                fontSize: isTop3 ? 17 : 13,
                shadows: isTop3
                    ? [
                        Shadow(
                          color: AppTheme.accent.withValues(alpha: 0.9),
                          blurRadius: 8,
                        ),
                        Shadow(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),

          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.border,
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.username.isNotEmpty
                        ? entry.username[0].toUpperCase()
                        : '?',
                    style: _streetFont(size: 13, spacing: 0),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              entry.username.toUpperCase(),
              style: _streetFont(
                size: isTop3 ? 13 : 12,
                color:
                    isTop3 ? AppTheme.textPrimary : AppTheme.textSecondary,
                spacing: isTop3 ? 1.5 : 1.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Row(
            children: [
              _ElectricSurgeIcon(active: isTop3),
              const SizedBox(width: 4),
              Text(
                '${entry.checkInCount}',
                style: GoogleFonts.rubikMonoOne(
                  color: AppTheme.accent,
                  fontSize: 15,
                  shadows: isTop3
                      ? [
                          Shadow(
                            color: AppTheme.accent.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isTop3) return row;

    return _NeonFlicker(
      child: Stack(
        children: [
          row,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: AppTheme.accent),
          ),
        ],
      ),
    );
  }
}

// ── Global Badge ──────────────────────────────────────────────────────────────

/// Displays the spot's country flag emoji + 3-letter city code in the app bar,
/// giving nomads instant geographic context at a glance.
///
/// Visible only when [Spot.countryCode] or [Spot.cityName] is non-null.
/// Falls back gracefully: shows just the flag if cityName is absent, just the
/// code if countryCode is absent.
class _GlobalBadge extends StatelessWidget {
  const _GlobalBadge({required this.spot});

  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final flag = spot.countryCode != null
        ? TimezoneUtils.flagEmoji(spot.countryCode!)
        : '';
    final code = TimezoneUtils.cityCode(spot.cityName);
    final label = [flag, code].where((s) => s.isNotEmpty).join(' ');
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: _streetFont(size: 9, color: AppTheme.accent, spacing: 1.2),
      ),
    );
  }
}

// ── Spot Meta Line (radius + local time) ─────────────────────────────────────

/// The subtitle row beneath the spot name in the app bar.
///
/// Shows: [radius] · [LOCAL HH:mm] (if timezone known)
///
/// Local time auto-updates every 30 seconds via [Stream.periodic] so the
/// display stays accurate without rebuilding the whole screen.
class _SpotMetaLine extends StatelessWidget {
  const _SpotMetaLine({required this.spot});

  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final radiusText = '${spot.radiusMeters}${l10n.radiusSuffix}';

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 30), (i) => i),
      builder: (context, _) {
        final timeStr = TimezoneUtils.localTimeString(spot.timezoneId);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              radiusText,
              style: _streetFont(
                size: 9,
                color: AppTheme.textSecondary,
                spacing: 2.5,
              ),
            ),
            if (timeStr.isNotEmpty) ...[
              Text(
                '  ·  ',
                style: _streetFont(
                  size: 9,
                  color: AppTheme.textSecondary,
                  spacing: 0,
                ),
              ),
              Text(
                '${l10n.localTimeLabel} $timeStr',
                style: _streetFont(
                  size: 9,
                  color: AppTheme.accent.withValues(alpha: 0.85),
                  spacing: 1.5,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Electric Surge Icon ───────────────────────────────────────────────────────

class _ElectricSurgeIcon extends StatelessWidget {
  const _ElectricSurgeIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 18),
      painter: _BoltPainter(active: active),
    );
  }
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.15, size.height * 0.48)
      ..lineTo(size.width * 0.48, size.height * 0.48)
      ..lineTo(size.width * 0.35, size.height)
      ..lineTo(size.width * 0.85, size.height * 0.52)
      ..lineTo(size.width * 0.52, size.height * 0.52)
      ..close();

    if (active) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppTheme.accent.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BoltPainter old) => old.active != active;
}
