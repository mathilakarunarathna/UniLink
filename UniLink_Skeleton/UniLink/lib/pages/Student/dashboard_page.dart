import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/dashboard/presentation/dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/skeleton_widgets.dart';
import '../../widgets/mesh_gradient_background.dart';
import '../../core/util/date_util.dart';
import 'order_tracking_view.dart';
import 'contact_admin_page.dart';
import '../../core/services/notification_service.dart';
import '../../data/global_state.dart';

// --- (Previous assets helper stays as is) ---
Widget _dashboardAssetImage({
  required String assetPath,
  required BoxFit fit,
  Alignment alignment = Alignment.center,
}) {
  final isNetwork = assetPath.startsWith('http');
  
  if (isNetwork) {
    return Image.network(
      assetPath,
      fit: fit,
      alignment: alignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: Colors.white.withValues(alpha: 0.1));
      },
      errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(context),
    );
  }

  return Image.asset(
    assetPath,
    fit: fit,
    alignment: alignment,
    errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(context),
  );
}

Widget _buildImageErrorPlaceholder(BuildContext context) {
  final colors = AppColors.of(context);
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.muted, colors.background],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.mutedForeground,
      ),
    ),
  );
}

void _openDashboardRoute(BuildContext context, String title, String route) {
  final navigator = Navigator.maybeOf(context);
  if (navigator == null) return;

  try {
    navigator.pushNamed(route, arguments: {'fromDashboard': true});
  } catch (_) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text('$title is not available right now.')),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Timer _timer;
  String _currentTime = "--:--:--";
  String _currentDate = "Loading Date...";

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().fetchDashboardData();
      
      // Initialize Real-time Notifications
      NotificationService().init();
    });

    // Listen for real-time notifications to show Snackbar
    GlobalState.latestNotification.addListener(_onNotificationReceived);
  }

  void _onNotificationReceived() {
    final notification = GlobalState.latestNotification.value;
    if (notification == null || !mounted) return;

    final colors = AppColors.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (notification['iconColor'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification['icon'] as IconData,
                  color: notification['iconColor'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification['title'] as String,
                      style: TextStyle(
                        color: colors.foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      notification['description'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    GlobalState.latestNotification.removeListener(_onNotificationReceived);
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final timeStr = "$h:$m:$s";

    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final dateStr =
        "${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}";

    if (mounted) {
      setState(() {
        _currentTime = timeStr;
        _currentDate = dateStr;
      });

      // Simulation: Change weather/shuttle occasionally
      if (now.second % 30 == 0) {
          final isSunny = now.second % 60 == 0;
          GlobalState.weatherInfo.value = {
            "temp": isSunny ? "29°C" : "27°C",
            "condition": isSunny ? "Sunny" : "Partly Cloudy",
            "icon": isSunny ? Icons.wb_sunny_rounded : Icons.wb_cloudy_rounded,
          };
          
          final routes = ["Main Hall \u2794 Gate 1", "Library \u2794 Hostel Block", "Complex \u2794 Main Gate"];
          final randomRoute = routes[now.second % routes.length];
          GlobalState.shuttleInfo.value = {
            "route": randomRoute,
            "eta": "${(now.second % 8) + 1} mins",
            "isActive": true,
          };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fullName = auth.userData?['fullName']?.toString().trim();
    final legacyName = auth.userData?['name']?.toString().trim();
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (legacyName != null && legacyName.isNotEmpty)
        ? legacyName
        : 'Student';

    final colors = AppColors.of(context);

    // ALL ICONS SET TO PURPLE AS REQUESTED
    final services = <_ServiceAction>[
      _ServiceAction(
        title: 'MySpot',
        subtitle: 'Parking',
        icon: Icons.local_parking,
        color: colors.campusViolet,
        route: '/myspot',
      ),
      _ServiceAction(
        title: 'Cafeteria',
        subtitle: 'Food Order',
        icon: Icons.restaurant_menu_rounded,
        color: colors.campusViolet,
        route: '/cafeteria',
      ),
      _ServiceAction(
        title: 'StudySpace',
        subtitle: 'Room Book',
        icon: Icons.import_contacts_rounded,
        color: colors.campusViolet,
        route: '/studyspace',
      ),
      _ServiceAction(
        title: 'EventPass',
        subtitle: 'Tickets',
        icon: Icons.local_activity_rounded,
        color: colors.campusViolet,
        route: '/eventpass',
      ),
      _ServiceAction(
        title: 'UniFeed',
        subtitle: 'Social',
        icon: Icons.feed_rounded,
        color: colors.campusViolet,
        route: '/unifeed',
      ),
      _ServiceAction(
        title: 'ShuttleSync',
        subtitle: 'Transport',
        icon: Icons.directions_bus_filled_rounded,
        color: colors.campusViolet,
        route: '/shuttlesync',
      ),
      _ServiceAction(
        title: 'Lost & Found',
        subtitle: 'Items',
        icon: Icons.manage_search_rounded,
        color: colors.campusViolet,
        route: '/lostfound',
      ),
      _ServiceAction(
        title: 'StayFinder',
        subtitle: 'Housing',
        icon: Icons.apartment_rounded,
        color: colors.campusViolet,
        route: '/stayfinder',
      ),
      _ServiceAction(
        title: 'Uni Map',
        subtitle: 'Navigation',
        icon: Icons.map_rounded,
        color: colors.campusViolet,
        route: '/unimap',
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: const BottomNavBar(currentRoute: '/dashboard'),
      body: MeshGradientBackground(
        child: SafeArea(
          child: Consumer<DashboardProvider>(
            builder: (context, dashboard, _) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(name: displayName, time: _currentTime, date: _currentDate),
                    const SizedBox(height: 24),
                    const _SearchRow(),
                    const SizedBox(height: 24),
                    const _PromoCarousel(),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Campus Services'),
                    const SizedBox(height: 16),
                    _ServicesGrid(services: services),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Live Insights'),
                    const SizedBox(height: 16),
                    const _LiveInsightsStrip(),
                    const SizedBox(height: 24),
                    _LiveOrderCard(email: auth.userData?['email']?.toString()),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'News Feed'),
                    const SizedBox(height: 16),
                    _NewsFeedStrip(items: dashboard.news ?? []),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Help & Support'),
                    const SizedBox(height: 16),
                    const _SupportSection(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final List<_ServiceAction> services;

  const _ServicesGrid({required this.services});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? colors.background.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colors.border.withValues(alpha: 0.4), width: 1.5),
          ),
          child: GridView.builder(
            itemCount: services.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              return _ServiceTile(service: services[index]);
            },
          ),
        ),
      ),
    );
  }
}

class _LiveInsightsStrip extends StatelessWidget {
  const _LiveInsightsStrip();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _WeatherWidget(),
        SizedBox(height: 12),
        _LiveShuttleStrip(),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String time;
  final String date;

  const _ProfileHeader({
    required this.name,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const _PulsingRing(),
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: _dashboardAssetImage(
                  assetPath: 'assets/images/student_profile.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherWidget extends StatelessWidget {
  const _WeatherWidget();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return ValueListenableBuilder(
      valueListenable: GlobalState.weatherInfo,
      builder: (context, data, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(data['icon'] as IconData, color: colors.campusAmber, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['condition']} \u2022 Campus Temp',
                      style: TextStyle(color: colors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Currently ${data['temp']}',
                      style: TextStyle(color: colors.foreground, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: colors.foreground.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: colors.mutedForeground,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search campus resources...',
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: colors.foreground.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.tune_rounded, size: 22, color: colors.foreground),
        ),
      ],
    );
  }
}

class _ServiceAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _ServiceAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _ServiceTile extends StatefulWidget {
  final _ServiceAction service;

  const _ServiceTile({required this.service});

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        _openDashboardRoute(context, widget.service.title, widget.service.route);
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0x331E1E2C) : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.service.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.service.icon,
                  color: widget.service.color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.service.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                widget.service.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsFeedStrip extends StatelessWidget {
  final List<dynamic> items;
  const _NewsFeedStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: List.generate(2, (index) => const DashboardCardSkeleton()),
        ),
      );
    }

    return Column(
      children: items.take(3).map((item) {
        return _NewsCard(item: item);
      }).toList(),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? colors.background.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 100,
              child: _buildNewsImage(context, item),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['category']?.toString().toUpperCase() ?? 'CAMPUS NEWS',
                      style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['title']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.foreground, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      item['date']?.toString() ?? '',
                      style: TextStyle(color: colors.mutedForeground, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsImage(BuildContext context, Map<String, dynamic> item) {
    final colors = AppColors.of(context);
    final String url = (item['imageUrl'] ?? item['image'] ?? item['url'] ?? '').toString();

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: colors.muted.withValues(alpha: 0.3),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _dashboardAssetImage(
          assetPath: 'assets/images/background.png',
          fit: BoxFit.cover,
        ),
      );
    }

    return _dashboardAssetImage(
      assetPath: url.isNotEmpty ? url : 'assets/images/background.png',
      fit: BoxFit.cover,
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  final String? email;
  const _LiveOrderCard({this.email});

  @override
  Widget build(BuildContext context) {
    if (email == null) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('studentEmail', isEqualTo: email)
          .where('status', whereIn: ['Pending', 'Preparing', 'Ready'])
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final order = snapshot.data!.docs.first;
        final data = order.data();
        final status = data['status'] ?? 'Pending';
        final shopName = data['shopName'] ?? 'Kitchen';
        final orderId = order.id;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        // 1-HOUR EXPIRATION LOGIC
        if (createdAt != null) {
          final age = DateTime.now().difference(createdAt);
          if (age.inMinutes > 60) {
            return const SizedBox.shrink();
          }
        }

        final estimatedReadyAt = DateUtil.parseNullable(data['estimatedReadyAt']);

        int minutesLeft = 0;
        if (estimatedReadyAt != null) {
          final diff = estimatedReadyAt.difference(DateTime.now());
          minutesLeft = diff.inMinutes;
          if (minutesLeft < 0) minutesLeft = 0;
        }

        IconData icon = LucideIcons.clock;
        Color statusColor = colors.primary;
        String statusText = "Order Received";

        if (status == 'Preparing') {
          icon = LucideIcons.utensils;
          statusColor = colors.campusAmber;
          statusText = minutesLeft > 0
              ? "Ready in $minutesLeft mins"
              : "Almost ready!";
        } else if (status == 'Ready') {
          icon = LucideIcons.checkCircle;
          statusColor = colors.campusEmerald;
          statusText = "Ready for Pickup";
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingView(orderId: orderId),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: TextStyle(
                          color: colors.foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: colors.mutedForeground,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  void _showContactOptions(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Contact Support',
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How can we help you today?',
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              _ContactOptionTile(
                title: 'Live Admin Chat',
                subtitle: 'Chat directly with NSBM support',
                icon: LucideIcons.messageCircle,
                color: colors.campusViolet,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactAdminPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ContactOptionTile(
                title: 'Administrative Office',
                subtitle: 'General inquiries and desk support',
                icon: LucideIcons.phone,
                color: colors.campusSky,
                onTap: () async {
                  final uri = Uri.parse('tel:+94115445000');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              const SizedBox(height: 12),
              _ContactOptionTile(
                title: 'Security & Emergency',
                subtitle: 'Immediate medical or safety assistance',
                icon: LucideIcons.shieldAlert,
                color: colors.campusRose,
                onTap: () async {
                  final uri = Uri.parse('tel:0112312112');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Send Feedback',
          style: TextStyle(
            color: colors.foreground,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your thoughts help us improve UniLink. What\'s on your mind?',
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              cursorColor: colors.campusViolet,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                hintStyle: TextStyle(color: colors.mutedForeground.withValues(alpha: 0.5)),
                filled: true,
                fillColor: colors.muted.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.campusViolet, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.mutedForeground, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              try {
                final user = FirebaseAuth.instance.currentUser;
                await FirebaseFirestore.instance.collection('feedbacks').add({
                  'text': text,
                  'studentEmail': user?.email ?? 'Anonymous',
                  'studentName': user?.displayName ?? 'Student',
                  'studentUid': user?.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'new',
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Your feedback has been submitted.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send feedback: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.campusViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.campusViolet.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.info, size: 40, color: colors.campusViolet),
            ),
            const SizedBox(height: 20),
            Text(
              'UniLink',
              style: TextStyle(
                color: colors.foreground,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Version 2.4.0',
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'UniLink is a premium campus ecosystem designed to streamline student life. From cafeteria orders to shuttle tracking, we connect all your university services in one seamless experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.foreground.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.campusViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: _SupportTile(
              title: 'Contact Us',
              icon: LucideIcons.phone,
              color: colors.campusViolet,
              onTap: () => _showContactOptions(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SupportTile(
              title: 'Feedback',
              icon: LucideIcons.messageSquare,
              color: colors.campusEmerald,
              onTap: () => _showFeedbackDialog(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SupportTile(
              title: 'About Us',
              icon: LucideIcons.info,
              color: colors.campusSky,
              onTap: () => _showAboutDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SupportTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: colors.foreground.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ContactOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContactOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: colors.mutedForeground.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveShuttleStrip extends StatelessWidget {
  const _LiveShuttleStrip();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: GlobalState.shuttleInfo,
      builder: (context, data, _) {
        if (!(data['isActive'] as bool)) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: colors.foreground.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.campusViolet.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_bus_rounded, color: colors.campusViolet, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _LiveDot(),
                        const SizedBox(width: 6),
                        Text(
                          'SHUTTLE TRACKER',
                          style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['route'] as String,
                      style: TextStyle(color: colors.foreground, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ARRIVING IN',
                    style: TextStyle(color: colors.mutedForeground, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    data['eta'] as String,
                    style: TextStyle(color: colors.campusViolet, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  final List<String> _promos = [
    'assets/images/cafeteria_promo.png',
    'assets/images/study_promo.png',
    'assets/images/event_promo.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _promos.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: _promos.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _dashboardAssetImage(
                      assetPath: _promos[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promos.length,
              (index) => Container(
                width: _currentPage == index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.of(context).primary : AppColors.of(context).muted,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  const _PulsingRing();

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return ValueListenableBuilder(
      valueListenable: GlobalState.globalNotifications,
      builder: (context, notifications, _) {
        final hasUnread = notifications.any((n) => n['isUnread'] == true);
        if (!hasUnread) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 56 + (14 * _controller.value),
              height: 56 + (14 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 1.0 - _controller.value),
                  width: 2,
                ),
              ),
            );
          },
        );
      }
    );
  }
}
