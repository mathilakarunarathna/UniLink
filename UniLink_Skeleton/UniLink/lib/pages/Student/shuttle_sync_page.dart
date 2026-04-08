import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class ShuttleSyncPage extends StatefulWidget {
  const ShuttleSyncPage({super.key});

  @override
  State<ShuttleSyncPage> createState() => _ShuttleSyncPageState();
}

class _ShuttleSyncPageState extends State<ShuttleSyncPage> {
  final TextEditingController _searchController = TextEditingController();
  final RegExp _timeSanitizer = RegExp(r'[^0-9:]');
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(BuildContext context, String? phoneNumber, String label) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      _showError(context, 'Invalid contact for $label');
      return;
    }
    
    final Uri url = Uri.parse('tel:${phoneNumber.replaceAll(' ', '')}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showError(context, 'Could not initiate call to $phoneNumber');
      }
    } catch (e) {
      _showError(context, 'Error launching dialer: ${e.toString()}');
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ULTRA-SAFE TIME PARSING
  bool _isLeavingSoon(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return false;
    try {
      final now = DateTime.now();
      // Extract only digits and colon
      final cleanStr = timeStr.replaceAll(_timeSanitizer, '');
      final parts = cleanStr.split(':');
      if (parts.length < 2) return false;
      
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      
      final departureInMinutes = hour * 60 + minute;
      final nowInMinutes = now.hour * 60 + now.minute;
      
      final diff = departureInMinutes - nowInMinutes;
      return diff > 0 && diff <= 30;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            /* PREMIUM HEADER SECTION */
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircularBackButton(context, colors),
                      _buildLiveBadge(colors),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'NSBM TRANSPORT',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find your ride before your next class',
                    style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 32, height: 1.1, letterSpacing: -1.0),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pick a route, check the timing, and catch your shuttle with real-time seat tracking.',
                    style: TextStyle(color: colors.mutedForeground, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5, letterSpacing: -0.2),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              children: [
                _buildSearchBar(colors),
                const SizedBox(height: 12),
                _buildEmergencyBadge(context, colors),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shuttles')
                  .orderBy('updatedAt', descending: true)
                  .limit(15)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error syncing fleet data.', style: TextStyle(color: colors.mutedForeground)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No active fleet nodes found.', style: TextStyle(color: colors.mutedForeground)));
                }

                final filteredShuttles = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final route = (data['route'] ?? '').toString().toLowerCase();
                  return route.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredShuttles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filteredShuttles[index].data() as Map<String, dynamic>;
                    return _buildSimpleShuttleCard(context, data, colors);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSearchBar(AppCustomColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.foreground.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w700, fontSize: 14),
        cursorColor: colors.primary,
        decoration: InputDecoration(
          hintText: 'Where are you heading today?',
          hintStyle: TextStyle(color: colors.mutedForeground.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmergencyBadge(BuildContext context, AppCustomColors colors) {
    return InkWell(
      onTap: () => _makeCall(context, '0112312112', 'Emergency'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.campusRose.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.campusRose.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.shieldAlert, color: colors.campusRose, size: 14),
            const SizedBox(width: 10),
            Text('NSBM Emergency Hotline', style: TextStyle(color: colors.campusRose, fontWeight: FontWeight.w800, fontSize: 11)),
            const Spacer(),
            Icon(LucideIcons.chevronRight, size: 12, color: colors.campusRose),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleShuttleCard(BuildContext context, Map<String, dynamic> data, AppCustomColors colors) {
    final String photoUrl = data['photoUrl'] ?? '';
    final String route = data['route'] ?? 'UNKNOWN';
    final bool leavingSoon = _isLeavingSoon(data['toCampus']);
    final String category = data['category'] ?? 'Standard';
    final String status = data['available'] == false ? 'Offline' : (data['maintenance'] == true ? 'Service' : 'Online');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /* Thumbnail & Status Indicator */
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl, 
                        width: 72, height: 72, 
                        fit: BoxFit.cover,
                        cacheWidth: 200, // Critical for performance
                        errorBuilder: (_, __, ___) => Container(
                          width: 72, height: 72, 
                          color: colors.muted.withValues(alpha: 0.1), 
                          child: Icon(LucideIcons.bus, size: 28, color: colors.mutedForeground),
                        ),
                      )
                    : Container(width: 72, height: 72, color: colors.muted.withValues(alpha: 0.1), child: Icon(LucideIcons.bus, size: 28, color: colors.mutedForeground)),
              ),
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: status == 'Online' ? colors.campusEmerald : (status == 'Service' ? colors.campusAmber : colors.campusRose),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.card, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          /* Core Information */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(route, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: colors.foreground, letterSpacing: -0.4))),
                    if (leavingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: colors.campusAmber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('SOON', style: TextStyle(color: colors.campusAmber, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('FLEET ${data['busNumber']} • $category', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: colors.primary.withValues(alpha: 0.7), letterSpacing: 0.4)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildCompactTime('ARRIVE', data['toCampus'], colors),
                    const SizedBox(width: 16),
                    _buildCompactTime('RETURN', data['fromCampus'], colors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          /* Compact Actions */
          Column(
            children: [
              _buildCompactAction(LucideIcons.phone, colors.primary, () => _makeCall(context, data['contact'], 'Driver')),
              const SizedBox(height: 8),
              _buildCompactAction(LucideIcons.shieldAlert, colors.campusRose, () => _makeCall(context, data['emergencyContact'], 'Hotline')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTime(String label, String? value, AppCustomColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: colors.mutedForeground, letterSpacing: 0.5)),
        Text(value ?? '--:--', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.foreground.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildCompactAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildLiveBadge(AppCustomColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background, // Match background for outer ring feel
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7, 
            decoration: BoxDecoration(
              color: colors.campusEmerald, 
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: colors.campusEmerald.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Live Sync', 
            style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularBackButton(BuildContext context, AppCustomColors colors) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.foreground.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(color: colors.border.withValues(alpha: 0.1)),
        ),
        child: Icon(LucideIcons.arrowLeft, size: 20, color: colors.primary),
      ),
    );
  }
}
