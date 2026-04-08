import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';

// --- Models & Data ---

enum RoomStatus { available, pending, booked }

class Faculty {
  final String id;
  final String name;
  final IconData icon;
  final Color Function(AppCustomColors) colorResolver;

  Faculty(this.id, this.name, this.icon, this.colorResolver);

  Color getColor(AppCustomColors colors) => colorResolver(colors);
}

class StudyRoom {
  final String id;
  final String facultyId;
  final String name;
  final int capacity;
  RoomStatus status;

  StudyRoom({
    required this.id,
    required this.facultyId,
    required this.name,
    required this.capacity,
    this.status = RoomStatus.available,
  });
}

class StudySpaceData {
  static final List<Faculty> faculties = [
    Faculty('F1', 'Library', LucideIcons.book, (c) => c.campusIndigo),
    Faculty('F2', 'Business', LucideIcons.briefcase, (c) => c.campusAmber),
    Faculty('F3', 'Computing', LucideIcons.laptop, (c) => c.campusTeal),
    Faculty('F4', 'Engineering', LucideIcons.wrench, (c) => c.campusEmerald),
  ];
}

// --- STUDENT PAGE ---

class StudySpacePage extends StatefulWidget {
  const StudySpacePage({super.key});

  @override
  State<StudySpacePage> createState() => _StudySpacePageState();
}

class _StudySpacePageState extends State<StudySpacePage> {
  String selectedFacultyId = 'F1';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Real-time synchronization state
  Map<String, RoomStatus> _roomStatusMap = {};
  bool _isLoading = true;
  StreamSubscription? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _initRealTimeEngine();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  void _initRealTimeEngine() {
    // Listen to ALL active bookings to determine "Live" status of rooms
    _bookingsSub = _firestore.collection('space_bookings').snapshots().listen((snapshot) {
      final nextMap = <String, RoomStatus>{};
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final roomId = data['roomId'] as String?;
        final statusStr = (data['status'] ?? '').toString().toLowerCase();
        
        if (roomId == null) continue;

        // Try to parse booking time
        final bookingDate = (data['date'] as Timestamp?)?.toDate();
        if (bookingDate == null) continue;

        // Simplified "Live" check: Is the booking for today?
        final isToday = bookingDate.year == now.year && 
                        bookingDate.month == now.month && 
                        bookingDate.day == now.day;

        if (isToday && (statusStr == 'confirmed' || statusStr == 'pending')) {
          // If already confirmed, it's 'booked'
          // If pending, mark as 'pending'
          nextMap[roomId] = statusStr == 'confirmed' ? RoomStatus.booked : RoomStatus.pending;
        }
      }

      if (mounted) {
        setState(() {
          _roomStatusMap = nextMap;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final faculties = StudySpaceData.faculties;

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
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('study_rooms').snapshots(),
            builder: (context, snapshot) {
              final List<StudyRoom> allRooms = snapshot.hasData 
                ? snapshot.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final roomId = d.id;
                    return StudyRoom(
                      id: roomId, 
                      facultyId: data['facultyId'] ?? 'F1', 
                      name: data['name'] ?? 'Room', 
                      capacity: data['capacity'] ?? 4,
                      status: _roomStatusMap[roomId] ?? RoomStatus.available,
                    );
                  }).toList()
                : [];

              final activeRooms = allRooms.where((r) => r.facultyId == selectedFacultyId).toList();
              final liveSummary = _calculateSummary(activeRooms);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        _buildCircleButton(LucideIcons.arrowLeft, () => Navigator.pop(context), colors),
                        const Spacer(),
                        _buildLiveBadge(colors),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'STADY SPACE',
                      style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiet Zones',
                      style: TextStyle(color: colors.foreground, fontSize: 36, height: 1.1, fontWeight: FontWeight.w900),
                    ),
                    
                    const SizedBox(height: 28),
                    _buildFacultyTabs(faculties, colors),

                    const SizedBox(height: 28),
                    // Legend
                    _buildLegend(colors),
                    
                    const SizedBox(height: 24),
                    // Live Metrics
                    _buildMetricsRow(liveSummary, colors),
                    
                    const SizedBox(height: 32),
                    Text('SELECT A ROOM', style: _labelStyle(colors)),
                    const SizedBox(height: 16),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (activeRooms.isEmpty)
                      _buildEmptyState(colors)
                    else
                      _buildRoomGrid(activeRooms, colors),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Map<String, int> _calculateSummary(List<StudyRoom> rooms) {
    int available = 0;
    int pending = 0;
    int booked = 0;
    for (var r in rooms) {
      if (r.status == RoomStatus.available) available++;
      else if (r.status == RoomStatus.pending) pending++;
      else booked++;
    }
    return {'available': available, 'pending': pending, 'booked': booked, 'total': rooms.length};
  }

  Widget _buildFacultyTabs(List<Faculty> faculties, AppCustomColors colors) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: faculties.length,
        itemBuilder: (context, index) {
          final f = faculties[index];
          final isSelected = f.id == selectedFacultyId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => selectedFacultyId = f.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? colors.primary : colors.border),
                ),
                child: Center(
                  child: Row(
                    children: [
                      Icon(f.icon, size: 16, color: isSelected ? Colors.white : colors.mutedForeground),
                      const SizedBox(width: 8),
                      Text(
                        f.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : colors.foreground,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(AppCustomColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _legendItem(colors.campusEmerald, 'Free', colors),
          _legendItem(colors.campusAmber, 'Wait', colors),
          _legendItem(colors.destructive, 'Busy', colors),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, AppCustomColors colors) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: colors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildMetricsRow(Map<String, int> summary, AppCustomColors colors) {
    return Row(
      children: [
        _metricBox('TOTAL', summary['total']!, colors.primary, colors),
        const SizedBox(width: 12),
        _metricBox('FREE', summary['available']!, colors.campusEmerald, colors),
        const SizedBox(width: 12),
        _metricBox('BUSY', summary['booked']!, colors.destructive, colors),
      ],
    );
  }

  Widget _metricBox(String label, int val, Color accent, AppCustomColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Text(val.toString(), style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: colors.mutedForeground, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomGrid(List<StudyRoom> rooms, AppCustomColors colors) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final r = rooms[index];
        Color statusColor;
        if (r.status == RoomStatus.available) statusColor = colors.campusEmerald;
        else if (r.status == RoomStatus.pending) statusColor = colors.campusAmber;
        else statusColor = colors.destructive;

        return InkWell(
          onTap: () => _handleRoomTap(r, colors),
          child: Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.doorOpen, color: statusColor, size: 24),
                const SizedBox(height: 8),
                Text(
                  r.name.replaceAll('Room ', ''),
                  style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 13),
                ),
                Text(
                  'Cap: ${r.capacity}',
                  style: TextStyle(color: colors.mutedForeground, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRoomTap(StudyRoom room, AppCustomColors colors) {
    if (room.status == RoomStatus.booked) {
      _showMessage('This room is currently occupied.');
      return;
    }
    _showBookingDialog(room, colors);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showBookingDialog(StudyRoom room, AppCustomColors colors) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(LucideIcons.calendarCheck, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reserve Room', style: TextStyle(color: colors.foreground, fontSize: 18, fontWeight: FontWeight.w900)),
                          Text(room.name, style: TextStyle(color: colors.mutedForeground, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _dialogPicker(LucideIcons.calendar, "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", () async {
                  final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 14)));
                  if (d != null) setDialogState(() => selectedDate = d);
                }, colors),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _dialogPicker(LucideIcons.clock, startTime.format(context), () async {
                      final t = await showTimePicker(context: context, initialTime: startTime);
                      if (t != null) setDialogState(() => startTime = t);
                    }, colors)),
                    const SizedBox(width: 12),
                    Expanded(child: _dialogPicker(LucideIcons.clock4, endTime.format(context), () async {
                      final t = await showTimePicker(context: context, initialTime: endTime);
                      if (t != null) setDialogState(() => endTime = t);
                    }, colors)),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: isSubmitting ? null : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final user = _auth.currentUser;
                        await _firestore.collection('space_bookings').add({
                          'roomId': room.id,
                          'roomName': room.name,
                          'facultyId': room.facultyId,
                          'studentName': user?.displayName ?? 'Student',
                          'studentEmail': user?.email ?? 'student@unilink.com',
                          'time': "${startTime.format(context)} - ${endTime.format(context)}",
                          'date': selectedDate,
                          'status': 'pending',
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showSuccessDialog();
                        }
                      } catch (e) {
                         setDialogState(() => isSubmitting = false);
                      }
                    },
                    child: isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: colors.mutedForeground, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogPicker(IconData icon, String val, VoidCallback onTap, AppCustomColors colors) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.muted.withOpacity(0.3), borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 10),
            Text(val, style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.campusEmerald.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(LucideIcons.checkCircle, color: colors.campusEmerald, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Success!', style: TextStyle(color: colors.foreground, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Your quiet zone request is now pending admin approval.', textAlign: TextAlign.center, style: TextStyle(color: colors.mutedForeground, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.pop(context),
                child: const Text('Great', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, AppCustomColors colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: colors.card, shape: BoxShape.circle, border: Border.all(color: colors.border)),
        child: Icon(icon, color: colors.foreground, size: 20),
      ),
    );
  }

  Widget _buildLiveBadge(AppCustomColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: colors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Live', style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  TextStyle _labelStyle(AppCustomColors colors) {
    return TextStyle(color: colors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2);
  }

  Widget _buildEmptyState(AppCustomColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(LucideIcons.searchX, color: colors.mutedForeground.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          Text('No rooms in this building.', textAlign: TextAlign.center, style: TextStyle(color: colors.mutedForeground, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
