import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/admin_bottom_nav_bar.dart';

class UniMapPage extends StatefulWidget {
  final bool isAdmin;
  const UniMapPage({super.key, this.isAdmin = false});

  @override
  State<UniMapPage> createState() => _UniMapPageState();
}

class _UniMapPageState extends State<UniMapPage> {
  String _selectedZone = 'Main Campus';
  final MapController _mapController = MapController();

  static const LatLng _campusCenter = LatLng(6.9271, 79.8612);

  static const Map<String, LatLng> _zoneLocations = {
    'Main Campus': LatLng(6.9271, 79.8612),
    'Library': LatLng(6.9279, 79.8621),
    'Engineering': LatLng(6.9262, 79.8604),
    'Cafeteria': LatLng(6.9280, 79.8601),
    'Hostel': LatLng(6.9256, 79.8627),
  };

  static const List<String> _zones = <String>[
    'Main Campus',
    'Library',
    'Engineering',
    'Cafeteria',
    'Hostel',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.muted, colors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 14),
                _buildHeroCard(colors),
                const SizedBox(height: 14),
                _buildQuickZones(colors),
                const SizedBox(height: 18),
                _sectionTitle('Campus Map', colors),
                const SizedBox(height: 10),
                _buildMapPreview(colors, theme),
                const SizedBox(height: 18),
                _sectionTitle('Navigation Tools', colors),
                const SizedBox(height: 10),
                _buildToolCard(
                  icon: LucideIcons.navigation,
                  title: 'Best Route Finder',
                  subtitle:
                      'Select start and destination points to get the quickest campus route.',
                  badge: 'Coming soon',
                  colors: colors,
                ),
                const SizedBox(height: 10),
                _buildToolCard(
                  icon: LucideIcons.landmark,
                  title: 'Building Directory',
                  subtitle:
                      'Find faculties, labs, offices, and services with searchable map pins.',
                  badge: 'Coming soon',
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/unimap'),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Icon(LucideIcons.arrowLeft, size: 20, color: colors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campus Map',
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'Navigate university buildings faster',
                style: TextStyle(color: colors.mutedForeground, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Icon(LucideIcons.map, size: 20, color: colors.primary),
        ),
      ],
    );
  }

  Widget _buildHeroCard(AppCustomColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primaryForeground.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryForeground.withValues(alpha: 0.18),
                  border: Border.all(
                    color: colors.primaryForeground.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  LucideIcons.navigation,
                  color: colors.primaryForeground,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryForeground.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Live map rollout',
                  style: TextStyle(
                    color: colors.primaryForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Find buildings, services, and routes in one place',
            style: TextStyle(
              color: colors.primaryForeground,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start with a zone below to prepare your path before classes.',
            style: TextStyle(
              color: colors.primaryForeground.withValues(alpha: 0.88),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickZones(AppCustomColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _zones.map((zone) {
          final selected = zone == _selectedZone;
          return InkWell(
            onTap: () {
              setState(() => _selectedZone = zone);
              final target = _zoneLocations[zone] ?? _campusCenter;
              _mapController.move(target, 17);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.16)
                    : colors.muted,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.35)
                      : colors.border,
                ),
              ),
              child: Text(
                zone,
                style: TextStyle(
                  color: selected ? colors.primary : colors.mutedForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title, AppCustomColors colors) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(AppCustomColors colors, ThemeData theme) {
    final selectedCenter = _zoneLocations[_selectedZone] ?? _campusCenter;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.campusTeal.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: colors.campusTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedZone,
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'Preview',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: selectedCenter,
                  initialZoom: 16,
                  minZoom: 13,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.unilink.studentapp',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: const [
                          LatLng(6.9271, 79.8612),
                          LatLng(6.9279, 79.8621),
                          LatLng(6.9280, 79.8601),
                        ],
                        color: colors.primary.withValues(alpha: 0.6),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: _zoneLocations.entries.map((entry) {
                      final isSelected = entry.key == _selectedZone;
                      return Marker(
                        point: entry.value,
                        width: 38,
                        height: 38,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colors.primary
                                : colors.campusTeal,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: colors.primaryForeground,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required AppCustomColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
