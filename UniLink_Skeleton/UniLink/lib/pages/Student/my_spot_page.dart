import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth to get current user
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

enum SpotType { car, bike }

enum SpotStatus { available, booked, pending }

class ParkingSpot {
  final String id;
  final SpotType type;
  SpotStatus status;
  String bookedTime;

  ParkingSpot(this.id, this.type, this.status, {this.bookedTime = ''});
}

class MySpotData {
  // We keep the base generation to show the grid, but statuses will be overridden by Firebase
  static final List<ParkingSpot> carSpots = List.generate(
    150,
    (index) => ParkingSpot(
      'C-${(index + 1).toString().padLeft(3, '0')}',
      SpotType.car,
      SpotStatus.available, // Default everything to available initially
    ),
  );

  static final List<ParkingSpot> bikeSpots = List.generate(
    250,
    (index) => ParkingSpot(
      'B-${(index + 1).toString().padLeft(3, '0')}',
      SpotType.bike,
      SpotStatus.available,
    ),
  );
}

class MySpotPage extends StatefulWidget {
  const MySpotPage({super.key});

  @override
  State<MySpotPage> createState() => _MySpotPageState();
}

class _MySpotPageState extends State<MySpotPage> {
  String? selectedSpotId;
  int _selectedVehicleType = 0; // 0 for Cars, 1 for Bikes
  int _selectedZone = 0;
  bool _isLoadingSpots = true;
  bool _isBooking = false;
  String? _spotsError;
  Map<String, SpotStatus> _firebaseSpotsMap = {};
  StreamSubscription<QuerySnapshot>? _parkingBookingsSub;

  @override
  void initState() {
    super.initState();
    _parkingBookingsSub = FirebaseFirestore.instance
        .collection('parking_bookings')
        .snapshots()
        .listen(
          (snapshot) {
            final nextMap = <String, SpotStatus>{};

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final docSpotId = (data['spotId'] ?? doc.id)
                  .toString()
                  .trim()
                  .toUpperCase();
              final statusStr = (data['status'] ?? '').toString().toLowerCase();

              if (statusStr == 'pending') {
                nextMap[docSpotId] = SpotStatus.pending;
              } else if (statusStr == 'booked') {
                nextMap[docSpotId] = SpotStatus.booked;
              }
            }

            if (!mounted) return;

            final selectedStatus = selectedSpotId == null
                ? SpotStatus.available
                : nextMap[selectedSpotId!] ?? SpotStatus.available;
            final shouldClearSelection = selectedStatus != SpotStatus.available;
            final dataChanged = !mapEquals(_firebaseSpotsMap, nextMap);

            if (!dataChanged && !_isLoadingSpots && !shouldClearSelection) {
              return;
            }

            setState(() {
              _firebaseSpotsMap = nextMap;
              _isLoadingSpots = false;
              _spotsError = null;
              if (shouldClearSelection) {
                selectedSpotId = null;
              }
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoadingSpots = false;
              _spotsError = 'Parking data load failed. Please check network.';
            });
          },
        );
  }

  @override
  void dispose() {
    _parkingBookingsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final liveSummary = _buildLiveSummary(_firebaseSpotsMap);

    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: const BottomNavBar(currentRoute: '/myspot'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.muted, colors.background],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 28),
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border.all(color: colors.border),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.foreground.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                            color: colors.muted,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.border,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              LucideIcons.arrowLeft,
                              color: colors.primary,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.muted,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Live parking',
                                style: TextStyle(
                                  color: colors.foreground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Campus Parking',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reserve a slot before you arrive',
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Select a free slot, confirm it in a clean popup, and keep your booking active until you arrive.',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _buildHeroMetric(
                          'Available',
                          liveSummary['available'] ?? 0,
                          colors.campusEmerald,
                          colors,
                        ),
                        const SizedBox(width: 12),
                        _buildHeroMetric(
                          'Pending',
                          liveSummary['pending'] ?? 0,
                          colors.campusAmber,
                          colors,
                        ),
                        const SizedBox(width: 12),
                        _buildHeroMetric(
                          'Booked',
                          liveSummary['booked'] ?? 0,
                          colors.destructive,
                          colors,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: colors.foreground.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLegendItem(colors.campusEmerald, "Available", colors),
                      _buildLegendItem(colors.campusAmber, "Pending", colors),
                      _buildLegendItem(colors.destructive, "Booked", colors),
                      _buildLegendItem(colors.primary, "Selected", colors),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primary,
                              colors.campusIndigo,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          LucideIcons.locateFixed,
                          color: colors.primaryForeground,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select a slot to book',
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap only an available tile. Pending tiles show security status, booked tiles are locked.',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _buildVehicleTabs(colors),
              ),
              const SizedBox(height: 14),

              // Zones Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildZoneTabs(
                  _selectedVehicleType == 0
                      ? ["Zone A (1-50)", "Zone B (51-100)", "Zone C (101-150)"]
                      : [
                          "Zone A (1-50)",
                          "Zone B (51-100)",
                          "Zone C (101-150)",
                          "Zone D (151-200)",
                          "Zone E (201-250)",
                        ],
                  colors,
                ),
              ),
              const SizedBox(height: 24),

              // Grid with Real-time Firebase Stream!
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isLoadingSpots
                    ? const Center(child: CircularProgressIndicator())
                    : (_spotsError != null
                          ? Center(
                              child: Text(
                                _spotsError!,
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : _buildGrid(_firebaseSpotsMap, colors)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _buildLiveSummary(Map<String, SpotStatus> statusMap) {
    final allSpots = _selectedVehicleType == 0
        ? MySpotData.carSpots
        : MySpotData.bikeSpots;
    final visibleStart = _selectedZone * 50;
    final visibleEnd = visibleStart + 50;
    final visibleSpots = allSpots.sublist(
      visibleStart,
      visibleEnd > allSpots.length ? allSpots.length : visibleEnd,
    );

    var available = 0;
    var pending = 0;
    var booked = 0;

    for (final spot in visibleSpots) {
      final status = statusMap[spot.id] ?? SpotStatus.available;
      if (status == SpotStatus.available) {
        available++;
      } else if (status == SpotStatus.pending) {
        pending++;
      } else if (status == SpotStatus.booked) {
        booked++;
      }
    }

    return {'available': available, 'pending': pending, 'booked': booked};
  }

  Widget _buildHeroMetric(String label, int value, Color color, AppCustomColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.foreground.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSpotTap(String spotId, AppCustomColors colors) async {
    setState(() => selectedSpotId = spotId);
    await _showBookingDialog(spotId, colors);
    if (!mounted) return;
    setState(() => selectedSpotId = null);
  }

  Future<void> _bookSpot({
    required String spotId,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final bookingAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final expiresAt = bookingAt.add(const Duration(minutes: 30));
    final currentUserEmail =
        (FirebaseAuth.instance.currentUser?.email ??
                'unknown.student@unilink.com')
            .trim()
            .toLowerCase();

    try {
      setState(() => _isBooking = true);

      final existingActiveBookingSnapshot = await FirebaseFirestore.instance
          .collection('parking_bookings')
          .where('studentEmail', isEqualTo: currentUserEmail)
          .where('status', whereIn: ['pending', 'booked'])
          .limit(1)
          .get();

      if (existingActiveBookingSnapshot.docs.isNotEmpty) {
        final existingBooking = existingActiveBookingSnapshot.docs.first;
        final existingSpotId =
            (existingBooking.data()['spotId'] ?? existingBooking.id).toString();

        if (existingSpotId != spotId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You already have an active booking for $existingSpotId. Free it before booking another slot.',
                ),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('parking_bookings')
          .doc(spotId)
          .set({
            'spotId': spotId,
            'status': 'pending',
            'studentEmail': currentUserEmail,
            'arrivalTime': time.format(context),
            'bookingAt': Timestamp.fromDate(bookingAt),
            'expiresAt': Timestamp.fromDate(expiresAt),
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spot $spotId pending. Arrive within 30 minutes.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book spot: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  Future<void> _showBookingDialog(String spotId, AppCustomColors colors) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formattedDate =
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.foreground.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.primary,
                                colors.campusIndigo,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            LucideIcons.mapPin,
                            color: colors.primaryForeground,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirm Booking',
                                style: TextStyle(
                                  color: colors.foreground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Spot $spotId',
                                style: TextStyle(
                                  color: colors.mutedForeground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                           _buildInputField(
                            LucideIcons.calendarDays,
                            formattedDate,
                            colors: colors,
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 7),
                                ),
                              );
                              if (pickedDate != null) {
                                setDialogState(() => selectedDate = pickedDate);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildInputField(
                            LucideIcons.clock,
                            selectedTime.format(context),
                            colors: colors,
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (pickedTime != null) {
                                setDialogState(() => selectedTime = pickedTime);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isBooking
                                ? null
                                : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: colors.border,
                              ),
                              foregroundColor: colors.foreground,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isBooking
                                ? null
                                : () async {
                                    await _bookSpot(
                                      spotId: spotId,
                                      date: selectedDate,
                                      time: selectedTime,
                                    );
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.primaryForeground,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _isBooking ? 'Booking...' : 'Confirm',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPendingInfoDialog(String spotId, AppCustomColors colors) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'Pending Confirmation',
            style: TextStyle(color: colors.foreground),
          ),
          content: Text(
            'Spot $spotId is pending and waiting for security confirmation. Please arrive at the gate and contact security if needed.',
            style: TextStyle(color: colors.mutedForeground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'OK',
                style: TextStyle(color: colors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleTabs(AppCustomColors colors) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _buildTab('Cars', LucideIcons.car, 0, colors),
          _buildTab('Bikes', LucideIcons.bike, 1, colors),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index, AppCustomColors colors) {
    final isSelected = _selectedVehicleType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedVehicleType = index;
          _selectedZone = 0;
          selectedSpotId = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primaryForeground : colors.mutedForeground,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colors.primaryForeground : colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneTabs(List<String> zones, AppCustomColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: zones.asMap().entries.map((entry) {
          final isSelected = _selectedZone == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedZone = entry.key;
                selectedSpotId = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.3)
                        : colors.border,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.mutedForeground,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(Map<String, SpotStatus> statusMap, AppCustomColors colors) {
    final allSpots = _selectedVehicleType == 0
        ? MySpotData.carSpots
        : MySpotData.bikeSpots;
    final visibleStart = _selectedZone * 50;
    final visibleEnd = visibleStart + 50;
    final visibleSpots = allSpots.sublist(
      visibleStart,
      visibleEnd > allSpots.length ? allSpots.length : visibleEnd,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: visibleSpots.length,
      itemBuilder: (context, index) {
        final spot = visibleSpots[index];
        final status = statusMap[spot.id] ?? SpotStatus.available;
        final isSelected = selectedSpotId == spot.id;

        return _buildSpotTile(spot, status, isSelected, colors);
      },
    );
  }

  Widget _buildSpotTile(
    ParkingSpot spot,
    SpotStatus status,
    bool isSelected,
    AppCustomColors colors,
  ) {
    final color = isSelected
        ? colors.primary
        : (status == SpotStatus.available
            ? colors.campusEmerald
            : (status == SpotStatus.pending
                ? colors.campusAmber
                : colors.destructive));

    return GestureDetector(
      onTap: status == SpotStatus.available
          ? () => _handleSpotTap(spot.id, colors)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : color.withValues(alpha: 1.0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            spot.id.split('-').last,
            style: TextStyle(
              color: colors.primaryForeground,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, AppCustomColors colors) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    IconData icon,
    String value, {
    required AppCustomColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 18),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              LucideIcons.chevronRight,
              color: colors.mutedForeground,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
