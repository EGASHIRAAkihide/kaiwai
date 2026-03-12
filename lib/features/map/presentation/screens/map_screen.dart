import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/check_in_repository.dart';
import '../../data/repositories/spot_repository.dart';
import '../../domain/models/spot.dart';
import '../widgets/spot_marker_widget.dart';
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
    // TODO(auth): remove this dev bypass before release.
    // Navigate directly so the street-style UI is visible without a login.
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spot: spot)),
    );
    return;

    // ignore: dead_code
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'ログインが必要です',
            style: TextStyle(color: AppTheme.textPrimary),
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
          builder: (_) => SpotDetailScreen(spot: spot),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.danger.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'チェックインに失敗しました',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _recenterOnUser() {
    final target = _userLocation ?? _tokyoDefault;
    _mapController.move(target, 15);
  }

  void _dismissSheet() {
    Navigator.of(context).pop();
    setState(() => _selectedSpot = null);
  }

  void _showSpotSheet(Spot spot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopOverlay(),
          if (_errorMessage != null) _buildErrorBanner(),
          _buildProximityBanner(),
        ],
      ),
      floatingActionButton: _buildRecenterFab(),
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
                      .withOpacity(0.08),
                  borderColor: (_selectedSpot?.id == s.id
                          ? AppTheme.accent
                          : AppTheme.accentDim)
                      .withOpacity(0.3),
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
      ],
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // App wordmark
            Text(
              '界隈',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppTheme.textPrimary,
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
        ),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppTheme.danger, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildProximityBanner() {
    final spot = _nearbySpot;
    final dist = _nearbySpotDistance;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      bottom: spot != null ? 100 : -140,
      left: 16,
      right: 16,
      child: spot != null
          ? _ProximityBanner(
              spot: spot,
              distanceMeters: dist?.round() ?? 0,
              onCheckIn: () => _performCheckIn(spot),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildRecenterFab() {
    return FloatingActionButton(
      onPressed: _recenterOnUser,
      tooltip: 'My location',
      child: const Icon(Icons.my_location_rounded, size: 22),
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
              color: Colors.blue.withOpacity(0.15 * _pulse.value),
              border: Border.all(
                color: Colors.blue.withOpacity(0.4 * _pulse.value),
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
                  color: Colors.blue.withOpacity(0.5),
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

/// Banner shown at the bottom of the map when the user enters a spot's radius.
class _ProximityBanner extends StatelessWidget {
  const _ProximityBanner({
    required this.spot,
    required this.distanceMeters,
    required this.onCheckIn,
  });

  final Spot spot;
  final int distanceMeters;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withOpacity(0.15),
              border: Border.all(color: AppTheme.accent, width: 1.5),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 14),
          // Spot info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spot.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${distanceMeters}m 以内',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // CTA
          FilledButton(
            onPressed: onCheckIn,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.background,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            child: const Text('界隈に入る'),
          ),
        ],
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
        color: AppTheme.surface.withOpacity(0.85),
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
