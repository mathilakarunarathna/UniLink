import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

class GateFeedPage extends StatefulWidget {
  final String gateName;
  final bool isEntryGate;

  const GateFeedPage({
    super.key,
    required this.gateName,
    required this.isEntryGate,
  });

  @override
  State<GateFeedPage> createState() => _GateFeedPageState();
}

class _GateFeedPageState extends State<GateFeedPage> {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.campusTeal.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: colors.foreground.withValues(alpha: 0.05)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.arrowLeft,
                            color: colors.foreground,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.gateName,
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            Text(
                              widget.isEntryGate
                                  ? 'Manage student arrivals'
                                  : 'Manage student departures',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 12,
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            colors.primary.withValues(alpha: 0.95),
                            colors.campusIndigo.withValues(alpha: 0.88),
                          ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID verification tools',
                          style: TextStyle(
                            color: colors.primaryForeground,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildActionBoxes(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isEntryGate
                        ? 'Live Pending Entries'
                        : 'Live Pending Departures',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colors.foreground,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('parking_bookings')
                        .where(
                          'status',
                          isEqualTo: widget.isEntryGate ? 'pending' : 'booked',
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: colors.primary,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.border),
                          ),
                          child: Center(
                            child: Text(
                              "No vehicles in queue.",
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final spotId = doc['spotId'] ?? 'Unknown';
                          final studentEmail =
                              doc['studentEmail'] ?? 'Unknown Student';
                          final docId = doc.id;

                          if (widget.isEntryGate) {
                            return _buildActionCard(
                              "Student Arrival",
                              "Spot: $spotId | $studentEmail",
                              LucideIcons.logIn,
                              colors.campusAmber,
                              "Confirm Entry",
                              () async {
                                await FirebaseFirestore.instance
                                    .collection('parking_bookings')
                                    .doc(docId)
                                    .update({'status': 'booked'});

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Entry Confirmed! Spot $spotId is now Booked.',
                                    ),
                                    backgroundColor: colors.primary,
                                  ),
                                );
                              },
                            );
                          } else {
                            return _buildActionCard(
                              "Student Departure",
                              "Spot: $spotId | $studentEmail",
                              LucideIcons.logOut,
                              colors.campusEmerald,
                              "Make Spot Available",
                              () async {
                                await FirebaseFirestore.instance
                                    .collection('parking_bookings')
                                    .doc(docId)
                                    .delete();

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Exit Confirmed! Spot $spotId is available again.',
                                    ),
                                    backgroundColor: colors.campusIndigo,
                                  ),
                                );
                              },
                            );
                          }
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Gate History logs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colors.foreground,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryLog(
                    'Student Entered',
                    'Spot: C-010',
                    '10 mins ago',
                  ),
                  _buildHistoryLog(
                    'Student Exited',
                    'Spot: C-045',
                    '25 mins ago',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIdDialog(BuildContext context) {
    final colors = AppColors.of(context);
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: Colors.transparent,
          title: Text(
            "Student ID Verification",
            style: TextStyle(color: colors.foreground, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Type the student ID manually below:",
                style: TextStyle(color: colors.mutedForeground),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idController,
                style: TextStyle(color: colors.foreground),
                decoration: InputDecoration(
                  labelText: "Enter Student ID",
                  labelStyle: TextStyle(color: colors.mutedForeground),
                  hintText: "e.g., IT20202020",
                  hintStyle: TextStyle(color: colors.mutedForeground.withValues(alpha: 0.5)),
                  prefixIcon: Icon(
                    LucideIcons.user,
                    color: colors.mutedForeground,
                  ),
                  filled: true,
                  fillColor: colors.muted.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.mutedForeground),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (idController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "ID ${idController.text.toUpperCase()} Verified!",
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.campusEmerald,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Verify",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionBoxes() {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildInputBox(
            "Scan ID",
            LucideIcons.scan,
            colors.primary,
            () => _showSimulatedScanner(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInputBox(
            "Enter ID",
            LucideIcons.keyboard,
            colors.campusIndigo,
            () => _showIdDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBox(
    String title,
    IconData iconData,
    Color color,
    VoidCallback onTap,
  ) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.foreground,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSimulatedScanner(BuildContext context) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 3), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext); // Close scanner
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "ID Verified Successfully!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.20),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Scanning Student ID...",
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.camera,
                          color: Colors.black26,
                          size: 64,
                        ),
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.primary, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    CircularProgressIndicator(color: colors.primary),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "Please hold the ID card inside the frame",
                  style: TextStyle(color: colors.mutedForeground, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    String title,
    String details,
    IconData iconData,
    Color color,
    String buttonText,
    VoidCallback onConfirm,
  ) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colors.foreground,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      details,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: onConfirm,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryLog(String title, String subtitle, String time) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Text(
              time,
              style: TextStyle(color: colors.mutedForeground, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
