import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_card.dart';

class StayFinderPage extends StatefulWidget {
  const StayFinderPage({super.key});

  @override
  State<StayFinderPage> createState() => _StayFinderPageState();
}

class _StayFinderPageState extends State<StayFinderPage> {
  String _filter = "all";

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: const BottomNavBar(currentRoute: '/stayfinder'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.background,
              colors.muted.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientHero(context),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryForeground.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.arrowLeft,
                          color: colors.primaryForeground,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "StayFinder",
                          style: TextStyle(
                            color: colors.primaryForeground,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Find your campus home",
                          style: TextStyle(
                            color: colors.primaryForeground.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filters & Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    // Filter Buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterButton("all", "All", colors),
                          const SizedBox(width: 8),
                          _buildFilterButton("on-campus", "On Campus", colors),
                          const SizedBox(width: 8),
                          _buildFilterButton("off-campus", "Off Campus", colors),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Live Stream Builder
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stay_listings')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No accommodations found.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // Local filtering based on selected tab
                        var docs = snapshot.data!.docs;
                        if (_filter != "all") {
                          docs = docs
                              .where((doc) => doc['type'] == _filter)
                              .toList();
                        }

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No places match your filter.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String name = data['name'] ?? 'Unknown';
                            final String type = data['type'] ?? 'off-campus';
                            final bool isAvailable =
                                data['isAvailable'] ?? false;
                            final num rating = data['rating'] ?? 0.0;
                            final String price = data['price'] ?? 'N/A';
                            final String emoji = data['emoji'] ?? '🏠';
                            final String distance = data['distance'] ?? '-';
                            final String contact = data['contact'] ?? 'N/A';
                            final List<dynamic> facilities =
                                data['facilities'] ?? [];
                            final bool isOnCampus = type == "on-campus";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CustomCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: colors.muted,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: colors
                                                            .foreground,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (isOnCampus
                                                                  ? colors
                                                                        .campusIndigo
                                                                  : colors
                                                                        .campusEmerald)
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      isOnCampus
                                                          ? "On Campus"
                                                          : "Off Campus",
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isOnCampus
                                                            ? colors
                                                                  .campusIndigo
                                                            : colors
                                                                  .campusEmerald,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.star,
                                                    size: 12,
                                                    color:
                                                        colors.campusAmber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rating.toString(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: colors
                                                          .mutedForeground,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(
                                                    LucideIcons.mapPin,
                                                    size: 12,
                                                    color: colors
                                                        .mutedForeground,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    distance,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: colors
                                                          .mutedForeground,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

                                              // Facilities Wrap
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: facilities.map((fac) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: colors.muted,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      fac.toString(),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: colors
                                                            .mutedForeground,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 12),

                                              // Price & Availability
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    price,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          colors.foreground,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (isAvailable
                                                                  ? colors
                                                                        .campusEmerald
                                                                  : colors
                                                                        .campusRose)
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      isAvailable
                                                          ? "Available"
                                                          : "Not Available",
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isAvailable
                                                            ? colors
                                                                  .campusEmerald
                                                            : colors
                                                                  .campusRose,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isOnCampus) ...[
                                      const SizedBox(height: 12),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.phone,
                                            size: 14,
                                            color: colors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            contact,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colors.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            "Call for details",
                                            style: TextStyle(
                                              color: colors.mutedForeground,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      String filterValue, String label, AppCustomColors colors) {
    final isActive = _filter == filterValue;
    return GestureDetector(
      onTap: () => setState(() => _filter = filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.primary : colors.card,
          border: Border.all(
            color: isActive ? colors.primary : colors.border,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? colors.primaryForeground : colors.foreground,
          ),
        ),
      ),
    );
  }
}
