import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_card.dart';

// --- STUDENT PAGE ---

class LostFoundPage extends StatefulWidget {
  const LostFoundPage({super.key});

  @override
  State<LostFoundPage> createState() => _LostFoundPageState();
}

class _LostFoundPageState extends State<LostFoundPage> {
  String _selectedFilter = 'All';

  Color _getStatusColor(String status, AppCustomColors colors) {
    if (status.startsWith('at_faculty_')) return colors.campusEmerald;
    switch (status) {
      case 'lost':
        return colors.campusRose;
      case 'found':
      case 'at_guard_room':
        return colors.campusEmerald;
      case 'claimed':
        return colors.campusAmber;
      default:
        return colors.mutedForeground;
    }
  }

  String _formatStatusText(String status) {
    if (status.startsWith('at_faculty_')) {
      return 'AT FACULTY (${status.split('_').last})';
    }
    switch (status) {
      case 'lost':
        return 'LOST';
      case 'at_guard_room':
        return 'AT GUARD';
      case 'claimed':
        return 'CLAIMED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    return "Recently";
  }

  void _showReportDialog(String type) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String? localImagePath;
    bool isOutside = false;
    String selectedFaculty = 'FOB';
    final faculties = ['FOB', 'FOC', 'FOE'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardColor,
              title: Text(
                type == 'lost' ? "Report Lost Item" : "Report Found Item",
                style: TextStyle(color: colors.foreground),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: colors.foreground),
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        labelStyle: TextStyle(color: colors.mutedForeground),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: TextStyle(color: colors.foreground),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: colors.mutedForeground),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      style: TextStyle(color: colors.foreground),
                      decoration: InputDecoration(
                        labelText:
                            'Location where it was ${type == 'lost' ? 'last seen' : 'found'}',
                        labelStyle: TextStyle(color: colors.mutedForeground),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Photo Upload UI
                    GestureDetector(
                      onTap: () async {
                        ImageSource? source = type == 'found'
                            ? ImageSource.camera
                            : ImageSource.gallery;
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: source,
                        );
                        if (image != null) {
                          setDialogState(() => localImagePath = image.path);
                        }
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: localImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(localImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    type == 'found'
                                        ? LucideIcons.camera
                                        : LucideIcons.image,
                                    color: colors.mutedForeground,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    type == 'found'
                                        ? "Tap to Take Photo"
                                        : "Tap to Add Photo",
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (type == 'found')
                      CheckboxListTile(
                        title: Text(
                          "Was this found outside a faculty building?",
                          style: TextStyle(fontSize: 14, color: colors.foreground),
                        ),
                        value: isOutside,
                        activeColor: colors.primary,
                        checkColor: colors.primaryForeground,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) =>
                            setDialogState(() => isOutside = val ?? false),
                      ),
                    if (type == 'found' && !isOutside) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedFaculty,
                        dropdownColor: theme.cardColor,
                        style: TextStyle(color: colors.foreground),
                        decoration: InputDecoration(
                          labelText: 'Select Faculty',
                          labelStyle: TextStyle(color: colors.mutedForeground),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary),
                          ),
                        ),
                        items: faculties
                            .map(
                              (faculty) => DropdownMenuItem(
                                value: faculty,
                                child: Text(faculty),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setDialogState(() {
                          if (val != null) selectedFaculty = val;
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: colors.mutedForeground)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.primaryForeground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final userName =
                          currentUser?.email?.split('@')[0] ?? "Student";
                      final userEmail =
                          currentUser?.email ?? "student@unilink.com";
                      final itemName = nameController.text.trim();
                      final itemDesc = descController.text.trim();
                      final itemLoc = locationController.text.trim();
                      final itemStatus = type == 'lost'
                          ? 'lost'
                          : (isOutside
                                ? 'at_guard_room'
                                : 'at_faculty_$selectedFaculty');

                      // Save to Firebase (Lost & Found)
                      await FirebaseFirestore.instance
                          .collection('lost_found_items')
                          .add({
                            'type': type,
                            'name': itemName,
                            'description': itemDesc,
                            'location': itemLoc,
                            'itemStatus': itemStatus,
                            'approvalStatus': 'pending',
                            'reportedBy': userName,
                            'reportedByEmail': userEmail,
                            'imageUrl': null,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Report sent to Admin for approval! 🕒",
                          ),
                          backgroundColor: colors.campusAmber,
                        ),
                      );
                    }
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.campusTeal.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: colors.background.withValues(alpha: 0.28)),
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
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            LucideIcons.arrowLeft,
                            color: colors.foreground,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lost & Found',
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            Text(
                              'Report missing items and help others recover',
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
                          colors.primary.withValues(alpha: 0.96),
                          colors.campusIndigo.withValues(alpha: 0.88),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colors.campusRose.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildReportActionButton(
                                icon: LucideIcons.search,
                                label: 'Report Lost',
                                onTap: () => _showReportDialog('lost'),
                                colors: colors,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReportActionButton(
                                icon: LucideIcons.checkSquare,
                                label: 'Report Found',
                                onTap: () => _showReportDialog('found'),
                                colors: colors,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Lost', 'Found'].map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildFilterPill(
                            label: filter,
                            isSelected: _selectedFilter == filter,
                            onTap: () =>
                                setState(() => _selectedFilter = filter),
                            colors: colors,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lost_found_items')
                        .where('approvalStatus', isEqualTo: 'approved')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 22,
                          ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(
                              'No items reported recently.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 13,
                              ),
                            ),
                        );
                      }

                      final items = snapshot.data!.docs.where((doc) {
                        if (_selectedFilter == 'All') return true;
                        return doc['type'] == _selectedFilter.toLowerCase();
                      }).toList();

                      if (items.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            'No $_selectedFilter items right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                  Icon(
                                    LucideIcons.listFilter,
                                    size: 16,
                                    color: colors.mutedForeground,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${items.length} item(s) in $_selectedFilter',
                                    style: TextStyle(
                                      color: colors.foreground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...items.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final docId = doc.id;
                            final statusColor = _getStatusColor(
                              data['itemStatus'],
                              colors,
                            );
                            final isMine =
                                data['reportedByEmail'] == currentUserEmail;
                            return _buildItemCard(
                              data: data,
                              statusColor: statusColor,
                              isMine: isMine,
                              colors: colors,
                              onClaim: () async {
                                await FirebaseFirestore.instance
                                    .collection('lost_found_items')
                                    .doc(docId)
                                    .update({'itemStatus': 'claimed'});
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Item marked as claimed!'),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppCustomColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 6),
            Icon(icon, color: colors.primaryForeground, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.primaryForeground,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppCustomColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? colors.primaryForeground
                : colors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard({
    required Map<String, dynamic> data,
    required Color statusColor,
    required bool isMine,
    required AppCustomColors colors,
    required Future<void> Function() onClaim,
  }) {
    final itemType = (data['type'] ?? 'item').toString().toLowerCase();
    final title = (data['name'] ?? 'Unnamed item').toString().trim();
    final description = (data['description'] ?? 'No description')
        .toString()
        .trim();
    final location = (data['location'] ?? 'Unknown location').toString().trim();
    final reporter = (data['reportedBy'] ?? 'Student').toString().trim();
    final isLost = itemType == 'lost';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              alignment: Alignment.center,
              child: Icon(
                isLost ? LucideIcons.search : LucideIcons.package,
                color: colors.mutedForeground,
                size: 18,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Unnamed item' : title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isLost
                                    ? colors.campusRose
                                    : colors.campusEmerald)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isLost ? 'LOST' : 'FOUND',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isLost
                              ? colors.campusRose
                              : colors.campusEmerald,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _formatStatusText(data['itemStatus']),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description.isEmpty ? 'No description' : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reported by $reporter',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 12,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location.isEmpty ? 'Unknown location' : location,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.calendar,
                      size: 12,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(data['timestamp']),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                if (isMine && data['itemStatus'] != 'claimed')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onClaim,
                        icon: const Icon(LucideIcons.badgeCheck, size: 16),
                        label: const Text('Mark Claimed'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ADMIN APPROVAL PAGE ---

class AdminLostFoundPage extends StatelessWidget {
  const AdminLostFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "Admin: Lost & Found Approvals",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lost_found_items')
            .where('approvalStatus', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No pending reports to approve. 🎉"),
            );
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "[${data['type'].toString().toUpperCase()}] ${data['name']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colors.foreground,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.campusAmber.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "PENDING",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.campusAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Description: ${data['description']}",
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Location: ${data['location']}",
                        style: TextStyle(
                          color: colors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Reported by: ${data['reportedByName'] ?? data['reportedByEmail']}",
                        style: TextStyle(
                          color: colors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // APPROVE / REJECT BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.destructive,
                                side: BorderSide(color: colors.destructive),
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('lost_found_items')
                                    .doc(docId)
                                    .delete();
                              },
                              child: const Text("Reject"),
                            ),
                          ),
                          const SizedBox(width: 12),
                           Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.campusEmerald,
                                foregroundColor: colors.primaryForeground,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('lost_found_items')
                                    .doc(docId)
                                    .update({'approvalStatus': 'approved'});

                                final tType = data['type'];
                                final tItemName = data['name'];
                                final tItemLoc = data['location'];
                                final tItemDesc = data['description'];
                                final tItemStatus = data['itemStatus'];
                                final tUserName =
                                    data['reportedBy'] ?? "Student";
                                final tUserEmail =
                                    data['reportedByEmail'] ??
                                    "student@unilink.com";

                                // Share to UniFeed
                                await FirebaseFirestore.instance
                                    .collection('unifeed_posts')
                                    .add({
                                      'type': 'post',
                                      'authorName': '$tUserName (Lost & Found)',
                                      'authorEmail': tUserEmail,
                                      'content': tType == 'lost'
                                          ? "I lost my $tItemName at $tItemLoc. Please help me find it!\nDetails: $tItemDesc"
                                          : "I found a $tItemName at $tItemLoc. I left it at ${tItemStatus == 'at_guard_room' ? 'the Security Guard Room' : 'the ${tItemStatus.toString().replaceAll('at_faculty_', '')} Faculty Office'}.\nDetails: $tItemDesc",
                                      'status': 'approved',
                                      'timestamp': FieldValue.serverTimestamp(),
                                      'likes': [],
                                      'commentsList': [],
                                      'shares': 0,
                                    });
                              },
                              child: const Text("Approve"),
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
      ),
    );
  }
}
