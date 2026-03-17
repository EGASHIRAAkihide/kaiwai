import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../data/repositories/check_in_repository.dart';
import '../../data/repositories/spot_repository.dart';
import '../../domain/models/spot.dart';
import '../widgets/spot_marker_widget.dart';
import 'create_spot_screen.dart';
import 'spot_detail_screen.dart';

/// The main map screen — full-screen dark map with spot markers.
///
/// Platform setup required before running:
///
/// iOS — add to ios/Runner/Info.plist:
/// ```xml
/// <key>NSLocationWhenInUseUsageDescription</key>
/// <string>KAIWAI uses your location to show nearby spots.</string>
/// ```
///
/// Android — add to android/app/src/main/AndroidManifest.xml:
/// ```xml
/// <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
/// <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
/// ```
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Default center: Tokyo (fallback when location is unavailable)
  static const LatLng _tokyoDefault = LatLng(35.6762, 139.6503);

  final _mapController = MapController();
  final _spotRepo = SpotRepository();
  final _checkInRepo = CheckInRepository();

  StreamSubscription<Position>? _positionSub;
  bool _hasCenteredOnUser = false;

  List<Spot> _spots = [];
  LatLng? _userLocation;
  Spot? _selectedSpot;
  Spot? _nearbySpot;        // closest spot currently within its radius
  double? _nearbySpotDistance; // metres to that spot
  bool _isLoadingLocation = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
    _loadSpots();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _startLocationStream() async {
    final hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // emit only when user moves ≥10 m
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
      (position) {
        if (!mounted) return;
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = latLng;
          _isLoadingLocation = false;
        });
        _updateNearbySpot();
        // Centre the map once on the first GPS fix; leave it alone after that
        // so the user can freely pan without being snapped back.
        if (!_hasCenteredOnUser) {
          _mapController.move(latLng, 15);
          _hasCenteredOnUser = true;
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = 'Could not get location.';
        });
      },
    );
  }

  Future<bool> _requestLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadSpots() async {
    try {
      debugPrint('[MapScreen] _loadSpots → starting fetchSpots');
      final spots = await _spotRepo.fetchSpots();
      debugPrint('[MapScreen] _loadSpots → received ${spots.length} spots');
      if (!mounted) return;
      if (spots.isEmpty) {
        setState(() {
          _spots = spots;
          _errorMessage = 'No spots in this area.';
        });
      } else {
        setState(() {
          _spots = spots;
          _errorMessage = null;
        });
      }
      _updateNearbySpot();
    } catch (e, stack) {
      debugPrint('[MapScreen] _loadSpots → ERROR: $e\n$stack');
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not load spots. ($e)');
    }
  }

  // ── Proximity ─────────────────────────────────────────────────────────────

  void _updateNearbySpot() {
    if (_userLocation == null || _spots.isEmpty) return;
    Spot? closest;
    double closestDist = double.infinity;
    for (final spot in _spots) {
      final dist = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        spot.latitude,
        spot.longitude,
      );
      if (dist <= spot.radiusMeters && dist < closestDist) {
        closest = spot;
        closestDist = dist;
      }
    }
    if (!mounted) return;
    setState(() {
      _nearbySpot = closest;
      _nearbySpotDistance = closest != null ? closestDist : null;
    });
  }

  // ── Interactions ─────────────────────────────────────────────────────────

  void _onSpotTapped(Spot spot) {
    setState(() => _selectedSpot = spot);
    _mapController.move(spot.latLng, 15.5);
    _showSpotSheet(spot);
  }

  Future<void> _performCheckIn(Spot spot) async {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          content: Text(
            'AUTH REQUIRED — LOGIN TO ENTER',
            style: GoogleFonts.robotoMono(
              color: AppTheme.danger,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
      return;
    }

    try {
      await _checkInRepo.checkIn(spotId: spot.id, userId: user.id);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SpotDetailScreen(
            spot: spot,
            userInsideSpot: _nearbySpot?.id == spot.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          content: Text(
            'CHECK-IN FAILED — TRY AGAIN',
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

  void _recenterOnUser() {
    final target = _userLocation ?? _tokyoDefault;
    _mapController.move(target, 15);
  }

  Future<void> _openCreateSpot() async {
    final location = _userLocation;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          content: Text(
            'GPS REQUIRED — WAITING FOR LOCATION',
            style: GoogleFonts.robotoMono(
              color: AppTheme.danger,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
      return;
    }
    final newId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CreateSpotScreen(
          initialLatitude: location.latitude,
          initialLongitude: location.longitude,
        ),
      ),
    );
    if (newId != null) _loadSpots();
  }

  void _dismissSheet() {
    Navigator.of(context).pop();
    setState(() => _selectedSpot = null);
  }

  void _showSpotSheet(Spot spot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => SpotInfoSheet(
        spot: spot,
        onCheckIn: () {
          _dismissSheet();
          _performCheckIn(spot);
        },
        onClose: _dismissSheet,
      ),
    ).then((_) {
      if (mounted) setState(() => _selectedSpot = null);
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Pull safe-area bottom once so all bottom-anchored widgets use the same
    // baseline — avoids the home-indicator overlap on notched devices.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bannerVisible = _nearbySpot != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      // FABs are managed inside the Stack so they can animate in sync with the
      // ProximityBanner and never overlap it.
      body: Stack(
        children: [
          _buildMap(),
          _buildTopOverlay(),
          if (_errorMessage != null) _buildErrorBanner(),
          _buildProximityBanner(safeBottom: safeBottom),
          _buildFabs(safeBottom: safeBottom, bannerVisible: bannerVisible),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation ?? _tokyoDefault,
        initialZoom: 14.5,
        maxZoom: 19,
        minZoom: 10,
        onTap: (_, __) {
          if (_selectedSpot != null) {
            Navigator.of(context).maybePop();
            setState(() => _selectedSpot = null);
          }
        },
      ),
      children: [
        // --- Dark base tile layer (Carto Dark Matter — no API key needed) ---
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: true,
          userAgentPackageName: 'com.kaiwai.app',
          maxZoom: 20,
        ),

        // --- Spot radius circles ---
        CircleLayer(
          circles: _spots
              .map(
                (s) => CircleMarker(
                  point: s.latLng,
                  radius: s.radiusMeters.toDouble(),
                  useRadiusInMeter: true,
                  color: (_selectedSpot?.id == s.id
                          ? AppTheme.accent
                          : AppTheme.accentDim)
                      .withValues(alpha: 0.08),
                  borderColor: (_selectedSpot?.id == s.id
                          ? AppTheme.accent
                          : AppTheme.accentDim)
                      .withValues(alpha: 0.3),
                  borderStrokeWidth: 1.2,
                ),
              )
              .toList(),
        ),

        // --- Spot markers ---
        MarkerLayer(
          markers: _spots
              .map(
                (s) => Marker(
                  point: s.latLng,
                  width: 56,
                  height: 56,
                  child: SpotMarkerWidget(
                    spot: s,
                    isSelected: _selectedSpot?.id == s.id,
                    onTap: () => _onSpotTapped(s),
                  ),
                ),
              )
              .toList(),
        ),

        // --- User location indicator ---
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 24,
                height: 24,
                child: _UserLocationDot(),
              ),
            ],
          ),

        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
            TextSourceAttribution('CartoDB'),
          ],
        ),
      ],
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // App wordmark — uses locale-aware style so Japanese CJK glyphs
            // get NotoSansJP (which ships bold weights) instead of the
            // generic 'monospace' fallback that renders thin on iOS.
            Text(
              '界隈',
              style: AppTheme.appTitleTheme(
                Localizations.localeOf(context),
              ).copyWith(
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
                decoration: TextDecoration.none,
              ),
            ),
            const Spacer(),

            // Spot count badge
            if (_spots.isNotEmpty)
              _Pill(label: '${_spots.length} spots nearby'),

            if (_isLoadingLocation) ...[
              const SizedBox(width: 8),
              const _Pill(label: 'Locating...'),
            ],

            // Identity button
            const SizedBox(width: 8),
            _IdButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    // Positioned below the top overlay, not at the bottom — keeps the
    // bottom area free for ProximityBanner and FABs.
    final safeTop = MediaQuery.of(context).padding.top;
    return Positioned(
      top: safeTop + 64,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        ),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppTheme.danger, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildProximityBanner({required double safeBottom}) {
    final spot = _nearbySpot;
    final dist = _nearbySpotDistance;
    final visible = spot != null;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      // Rests just above the home indicator when visible; slides below the
      // screen when hidden.  FABs animate to clear this space (see _buildFabs).
      bottom: visible ? safeBottom + 16 : -(safeBottom + _kBannerHeight + 40),
      left: 16,
      right: 16,
      child: visible
          ? ProximityBanner(
              spot: spot,
              distanceMeters: dist?.round() ?? 0,
              onCheckIn: () => _performCheckIn(spot),
            )
          : const SizedBox.shrink(),
    );
  }

  // ProximityBanner outer height: vertical padding (16×2) + Row content (44).
  static const double _kBannerHeight = 76.0;
  // Gap between the top of the ProximityBanner and the bottom of the FABs.
  static const double _kFabBannerGap = 12.0;

  Widget _buildFabs({required double safeBottom, required bool bannerVisible}) {
    // When the ProximityBanner slides in, the FABs animate upward so they
    // always sit directly above the banner without any overlap.
    final bottom = bannerVisible
        ? safeBottom + 16 + _kBannerHeight + _kFabBannerGap
        : safeBottom + 16;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      right: 16,
      bottom: bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Recenter — small, secondary
          FloatingActionButton.small(
            heroTag: 'recenter',
            onPressed: _recenterOnUser,
            tooltip: 'My location',
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            shape: const CircleBorder(
              side: BorderSide(color: AppTheme.border),
            ),
            child: const Icon(Icons.my_location_rounded, size: 18),
          ),
          const SizedBox(height: 12),
          // Create Kaiwai — primary accent
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _openCreateSpot,
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.background,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            label: Text(
              '+ KAIWAI',
              style: GoogleFonts.robotoMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

/// Animated pulsing dot for the user's current location.
class _UserLocationDot extends StatefulWidget {
  @override
  State<_UserLocationDot> createState() => _UserLocationDotState();
}

class _UserLocationDotState extends State<_UserLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          Container(
            width: 24 * _pulse.value,
            height: 24 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.15 * _pulse.value),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.4 * _pulse.value),
                width: 1,
              ),
            ),
          ),
          // Core dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade400,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable `[ ID ]` chip in the top overlay — opens ProfileScreen.
class _IdButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ProfileScreen.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.85),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
        ),
        child: Text(
          '[ ID ]',
          style: GoogleFonts.robotoMono(
            color: AppTheme.accent,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

/// A small frosted glass pill label for the top overlay.
class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
