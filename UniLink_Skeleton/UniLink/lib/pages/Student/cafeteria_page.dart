// ignore_for_file: unused_element, unused_field, unused_local_variable

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/skeleton_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/payhere_simulator.dart';
import '../../core/services/payment_service.dart';
import '../../data/global_state.dart';

const String _payHereMerchantId = String.fromEnvironment(
  'PAYHERE_MERCHANT_ID',
  defaultValue: '',
);
const String _payHereNotifyUrl = String.fromEnvironment(
  'PAYHERE_NOTIFY_URL',
  defaultValue:
      'https://your-domain.okexample.com/api/v1/cafeteria/payhere/notify',
);
const bool _payHereSandbox = bool.fromEnvironment(
  'PAYHERE_SANDBOX',
  defaultValue: true,
);
final bool _isPayHereNotifyUrlConfigured =
    _payHereNotifyUrl != '' && !_payHereNotifyUrl.contains('okexample.com');

// No palette class needed anymore. Using AppCustomColors extension.

class Shop {
  final String id;
  final String name;
  final String description;
  final String time;
  final IconData icon;
  final int colorIndex;
  final String? image;
  final String category;

  Shop(
    this.id,
    this.name,
    this.description,
    this.time,
    this.icon,
    this.colorIndex, {
    this.image,
    this.category = 'Fast Food',
  });

  Color color(BuildContext context) {
    final colors = AppColors.of(context);
    final palette = [
      colors.primary,
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFD946EF),
      const Color(0xFFF43F5E),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
    ];
    return palette[colorIndex % palette.length];
  }
}

class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int quantity;
  final int preparationMinutes;
  final String category;
  final String emoji;
  final String? imagePath;

  MenuItem(
    this.id,
    this.name,
    this.description,
    this.price,
    this.currency,
    this.quantity,
    this.preparationMinutes,
    this.category,
    this.emoji, [
    this.imagePath,
  ]);
}

class CafeteriaPage extends StatefulWidget {
  const CafeteriaPage({super.key});

  @override
  State<CafeteriaPage> createState() => _CafeteriaPageState();
}

class _CafeteriaPageState extends State<CafeteriaPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fast Food',
    'Coffee',
    'Healthy',
    'Snacks',
    'Dessert',
  ];

  final Map<String, IconData> _categoryIcons = {
    'All': LucideIcons.layoutGrid,
    'Fast Food': LucideIcons.pizza,
    'Coffee': LucideIcons.coffee,
    'Healthy': LucideIcons.leaf,
    'Snacks': LucideIcons.apple,
    'Dessert': LucideIcons.iceCream,
  };

  Shop _shopFromFirestore(Map<String, dynamic> data, String docId, int index) {
    final icons = <IconData>[
      LucideIcons.utensilsCrossed,
      LucideIcons.coffee,
      LucideIcons.store,
      LucideIcons.cupSoda,
    ];
    final icon = icons[index % icons.length];
    final rawName = (data['shopName'] ?? data['name'] ?? '').toString().trim();
    final rawDescription = (data['description'] ?? 'Campus cafeteria shop').toString().trim();
    final rawTime = (data['openingHours'] ?? data['time'] ?? '08:00 AM - 08:00 PM').toString().trim();
    final rawCategory = (data['category'] ?? 'Fast Food').toString().trim();
    final rawImage = data['image']?.toString().trim();

    return Shop(
      docId,
      rawName.isEmpty ? 'Campus Cafeteria' : rawName,
      rawDescription.isEmpty ? 'Campus cafeteria shop' : rawDescription,
      rawTime.isEmpty ? '08:00 AM - 08:00 PM' : rawTime,
      icon,
      index,
      image: rawImage?.isEmpty == true ? null : rawImage,
      category: rawCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: const BottomNavBar(currentRoute: '/cafeteria'),
      body: Stack(
        children: [
          // 1. ADVANCED MESH GRADIENT BACKGROUND
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.12),
                    colors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200, right: -100,
            child: Container(
              width: 600, height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.campusTeal.withValues(alpha: 0.08),
                    colors.campusTeal.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('cafeteria_shops')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final shopsDocs = snapshot.data?.docs ?? [];
                
                // FILTERING LOGIC
                var shops = shopsDocs.asMap().entries.map((entry) => _shopFromFirestore(entry.value.data(), entry.value.id, entry.key)).toList();
                
                if (_searchQuery.isNotEmpty) {
                  shops = shops.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }
                if (_selectedCategory != 'All') {
                  shops = shops.where((s) => s.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /* PREMIUM HEADER & SEARCH SECTION */
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCircularBackButton(context, colors),
                              _buildLiveBadge(colors, shops.length),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'CAMPUS DINING',
                            style: TextStyle(
                              color: colors.primary, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 12, 
                              letterSpacing: 2.0,
                              shadows: [Shadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 10)],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fuel your day with\ncampus favorites',
                            style: TextStyle(
                              color: colors.foreground, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 36, 
                              height: 1.0, 
                              letterSpacing: -1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          // MODERN SEARCH BAR
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(color: colors.foreground, fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search restaurants or cafes...',
                                hintStyle: TextStyle(color: colors.mutedForeground, fontSize: 14, fontWeight: FontWeight.w600),
                                icon: Icon(LucideIcons.search, color: colors.primary, size: 18),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          // CATEGORY CHIPS
                          SizedBox(
                            height: 38,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final isSelected = _selectedCategory == cat;
                                  final icon = _categoryIcons[cat] ?? LucideIcons.helpCircle;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                            onTap: () => setState(() => _selectedCategory = cat),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? colors.primary : colors.card,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.1)),
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: colors.primary.withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            )
                                          ] : [],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(icon, color: isSelected ? Colors.white : colors.mutedForeground, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              cat,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : colors.mutedForeground,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const SizedBox(height: 24),
                          if (_searchQuery.isEmpty && _selectedCategory == 'All')
                            _buildTopPicksSection(context, colors, shops),
                          Row(
                            children: [
                              Text(
                                "Restaurants & Cafes",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colors.foreground, letterSpacing: -0.8),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.listFilter, color: colors.primary, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                      
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Column(
                          children: List.generate(3, (index) => const ShopCardSkeleton()),
                        )
                      else if (shops.isEmpty)
                        _buildPremiumEmptyState(context, colors)
                      else
                          ...shops.map((shop) => _buildPremiumShopCard(context, colors, shop)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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

  Widget _buildPremiumEmptyState(BuildContext context, AppCustomColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      decoration: BoxDecoration(
        color: isDark ? colors.background.withValues(alpha: 0.3) : colors.muted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.store, size: 48, color: colors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Campus Kitchen Preparing...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.foreground,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We are currently onboarding new restaurants and updating their menus. Check back soon for more delicious options!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.mutedForeground,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  

  Widget _buildTopPicksSection(BuildContext context, AppCustomColors colors, List<Shop> shops) {
    if (shops.length < 2) return const SizedBox.shrink();
    final featured = shops.take(2).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TOP PICKS', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
            const Spacer(),
            Icon(LucideIcons.sparkles, color: colors.campusAmber, size: 16),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final shop = featured[index];
              return _buildFeaturedCard(context, colors, shop);
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFeaturedCard(BuildContext context, AppCustomColors colors, Shop shop) {
    final shopColor = shop.color(context);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopMenuPage(shop: shop))),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [shopColor, shopColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: shopColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30, bottom: -30,
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(shop.icon, size: 180, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Featured', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ),
                    const Spacer(),
                    Hero(
                      tag: 'shop_name_featured_${shop.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          shop.name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.description,
                      maxLines: 2,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        const Text('4.9', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(LucideIcons.arrowRight, color: shopColor, size: 18),
                        ),
                      ],
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

  Widget _buildPremiumShopCard(BuildContext context, AppCustomColors colors, Shop shop) {
    final shopColor = shop.color(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopMenuPage(shop: shop))),
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -40, top: -10, bottom: -10, width: 180,
                  child: Opacity(
                    opacity: 0.45,
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: shop.image != null
                            ? Image.network(shop.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                            : Image.asset('assets/images/campus_cafe_thumbnail_1775582193301.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'shop_icon_${shop.id}',
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [shopColor.withValues(alpha: 0.2), shopColor.withValues(alpha: 0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: shopColor.withValues(alpha: 0.2)),
                          ),
                          child: Center(child: Icon(shop.icon, color: shopColor, size: 32)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Hero(
                                    tag: 'shop_name_${shop.id}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        shop.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: colors.foreground, letterSpacing: -0.5),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _PulsingIndicator(color: colors.campusEmerald),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(shop.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.mutedForeground)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildStatusBadge(colors, shop.category.toUpperCase(), colors.primary),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.clock, size: 12, color: colors.mutedForeground),
                                    const SizedBox(width: 4),
                                    Text('15 MIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colors.mutedForeground)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: colors.foreground.withValues(alpha: 0.05), shape: BoxShape.circle),
                        child: Icon(LucideIcons.chevronRight, size: 18, color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppCustomColors colors, String label, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(AppCustomColors colors, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingIndicator(color: colors.campusEmerald),
          const SizedBox(width: 8),
          Text(
            '$count Live Shops', 
            style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }
}

class ShopMenuPage extends StatefulWidget {
  final Shop shop;

  const ShopMenuPage({super.key, required this.shop});

  @override
  State<ShopMenuPage> createState() => _ShopMenuPageState();
}

class _ShopMenuPageState extends State<ShopMenuPage> {
  List<MenuItem> menuItems = [];
  bool _menuLoading = true;
  bool _isPlacingOrder = false;
  String? _savedCardToken;
  String? _savedCardMask;
  String _savedCardLabel = 'Saved Card';
  String _selectedCardMode = 'new';
  String selectedCategory = "All";
  String _searchQuery = '';


  final Map<int, int> cart = {};

  @override
  void initState() {
    super.initState();
    _loadMenuForShop(widget.shop.id);
    _loadCheckoutPreference();
  }

  Future<void> _loadCheckoutPreference() async {
    try {
      final paymentService = PaymentService();
      final details = await paymentService.getSavedCardDetails();

      if (mounted) {
        setState(() {
          _savedCardToken = details['payhereCustomerToken'];
          _savedCardMask = details['savedCardMask'];
          _savedCardLabel = details['payhereCardLabel'] ?? 'Saved Card';
          _selectedCardMode = (_savedCardToken != null) ? 'saved' : 'new';
        });
      }
    } catch (_) {
      return;
    }
  }

  Future<void> _saveCheckoutPreferenceToProfile(bool remember) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'saveCardForFutureOrders': remember,
      'preferredCheckoutGateway': remember
          ? 'Card Preapproval'
          : 'Card One-time',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadMenuForShop(String shopId) async {
    if (mounted) {
      setState(() => _menuLoading = true);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cafeteria_menu')
          .where('shopId', isEqualTo: shopId)
          .get();

      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final status = (data['status'] ?? 'Available')
                .toString()
                .trim()
                .toLowerCase();
            if (status == 'out of stock' || status == 'unavailable') {
              return null;
            }

            final name = (data['name'] ?? '').toString().trim();
            if (name.isEmpty) return null;

            final quantity = _parseQuantity(data['quantity']);
            if (quantity <= 0) return null;

            final category = (data['category'] ?? 'General').toString().trim();
            final description = (data['description'] ?? '').toString().trim();
            final currency = (data['currency'] ?? 'LKR')
                .toString()
                .trim()
                .toUpperCase();
            final imagePath = (data['image'] ?? data['imageUrl'] ?? '')
                .toString()
                .trim();
            final prep = _parseQuantity(data['preparationMinutes']);

            return MenuItem(
              doc.id.hashCode,
              name,
              description,
              _parsePrice(data['price']),
              currency.isEmpty ? 'LKR' : currency,
              quantity,
              prep <= 0 ? 15 : prep,
              category.isEmpty ? 'General' : category,
              _emojiForCategory(category),
              imagePath.isEmpty ? null : imagePath,
            );
          })
          .whereType<MenuItem>()
          .toList();

      if (mounted) {
        setState(() => menuItems = items);
      }
    } catch (_) {
      if (mounted) {
        setState(() => menuItems = []);
      }
    } finally {
      if (mounted) {
        setState(() => _menuLoading = false);
      }
    }
  }

  double _parsePrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  int _parseQuantity(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toDouble().floor();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  String _emojiForCategory(String rawCategory) {
    final c = rawCategory.toLowerCase();
    if (c.contains('drink') || c.contains('coffee')) return '☕';
    if (c.contains('juice') || c.contains('smoothie')) return '🧃';
    if (c.contains('dessert') || c.contains('sweet')) return '🍰';
    if (c.contains('snack') || c.contains('bite')) return '🥪';
    if (c.contains('rice') || c.contains('meal') || c.contains('lunch')) {
      return '🍛';
    }
    return '🍽️';
  }

  String _formatPrice(double amount, String currencyCode) {
    final c = currencyCode.trim().isEmpty
        ? 'LKR'
        : currencyCode.trim().toUpperCase();
    return '$c ${amount.toStringAsFixed(2)}';
  }

  String get _checkoutCurrency {
    if (cart.isEmpty || menuItems.isEmpty) return 'LKR';
    final firstId = cart.keys.first;
    final item = menuItems.firstWhere(
      (e) => e.id == firstId,
      orElse: () => menuItems.first,
    );
    return item.currency;
  }

  String get _checkoutOrderSummary {
    if (cart.isEmpty) return 'Empty order';
    return cart.entries
        .map((entry) {
          final item = menuItems.firstWhere((e) => e.id == entry.key);
          return '${entry.value}x ${item.name}';
        })
        .join(', ');
  }

  bool get _hasMixedCurrencies {
    if (cart.isEmpty || menuItems.isEmpty) return false;
    final currency = _checkoutCurrency;
    for (final entry in cart.entries) {
      final item = menuItems.firstWhere(
        (e) => e.id == entry.key,
        orElse: () => menuItems.first,
      );
      if (item.currency != currency) return true;
    }
    return false;
  }

  int get totalItems => cart.values.fold(0, (a, b) => a + b);

  double get totalPrice {
    double total = 0;
    cart.forEach((id, qty) {
      final item = menuItems.firstWhere((e) => e.id == id);
      total += item.price * qty;
    });
    return total;
  }

  void addToCart(int id) {
    final item = menuItems.firstWhere((e) => e.id == id);
    final current = cart[id] ?? 0;
    if (current >= item.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${item.quantity} available for ${item.name}.'),
        ),
      );
      return;
    }
    setState(() => cart[id] = current + 1);
  }

  void removeFromCart(int id) {
    setState(() {
      final current = cart[id];
      if (current == null) return;
      if (current <= 1) {
        cart.remove(id);
      } else {
        cart[id] = current - 1;
      }
    });
  }

  Future<Map<String, String>> _resolvePayHereCustomerDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase() ?? '';
    String fullName = (user?.displayName ?? email.split('@').first).trim();
    if (fullName.isEmpty) fullName = 'Student User';

    String phone = '0771234567';
    String address = 'UniLink Campus';
    String city = 'Colombo';
    String country = 'Sri Lanka';

    if (user?.uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        final data = snap.data();
        if (data != null) {
          final n = (data['name'] ?? data['displayName'] ?? '')
              .toString()
              .trim();
          if (n.isNotEmpty) fullName = n;
          final p = (data['phone'] ?? '').toString().trim();
          if (p.isNotEmpty) phone = p;
          final a = (data['address'] ?? data['deliveryAddress'] ?? '')
              .toString()
              .trim();
          if (a.isNotEmpty) address = a;
          final c = (data['city'] ?? '').toString().trim();
          if (c.isNotEmpty) city = c;
          final co = (data['country'] ?? '').toString().trim();
          if (co.isNotEmpty) country = co;
        }
      } catch (_) {}
    }

    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    return {
      'firstName': parts.isNotEmpty ? parts.first : 'Student',
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : 'User',
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
    };
  }

  Map<String, dynamic> _buildPayHerePaymentObject({
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required String currency,
    required Map<String, String> customerDetails,
  }) {
    final paymentObject = <String, dynamic>{
      'sandbox': _payHereSandbox,
      'merchant_id': _payHereMerchantId,
      'notify_url': _payHereNotifyUrl,
      'order_id': orderId,
      'items': _checkoutOrderSummary,
      'amount': totalAmount,
      'currency': currency,
      'first_name': customerDetails['firstName'],
      'last_name': customerDetails['lastName'],
      'email': customerDetails['email'],
      'phone': customerDetails['phone'],
      'address': customerDetails['address'],
      'city': customerDetails['city'],
      'country': customerDetails['country'],
      'custom_1': widget.shop.id,
      'custom_2': orderNumber,
    };

    int i = 1;
    cart.forEach((id, qty) {
      final item = menuItems.firstWhere((e) => e.id == id);
      paymentObject['item_number_$i'] = item.id.toString();
      paymentObject['item_name_$i'] = item.name;
      paymentObject['amount_$i'] = item.price;
      paymentObject['quantity_$i'] = qty.toString();
      i++;
    });

    return paymentObject;
  }

  Future<void> _finalizePaidOrder({
    required String paymentId,
    required String orderId,
    required String orderNumber,
    required String currency,
    required double totalAmount,
    required List<Map<String, dynamic>> orderItems,
    required Map<String, String> customerDetails,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email?.trim().toLowerCase() ?? '';

      final activeOrder = await FirebaseFirestore.instance
          .collection('orders')
          .where('studentEmail', isEqualTo: email)
          .where('status', whereIn: ['Pending', 'Preparing', 'Ready'])
          .limit(1)
          .get();

      if (!mounted) return;

      if (activeOrder.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have an active food order.'),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set({
            'orderId': orderId,
            'orderNumber': orderNumber,
            'paymentId': paymentId,
            'paymentGateway': 'Card',
            'orderType': 'Food',
            'type': 'Food', // Staff portal uses 'type' for label
            'shopId': widget.shop.id,
            'shopName': widget.shop.name,
            'studentEmail': email,
            'studentUid': user?.uid,
            'customerFirstName': customerDetails['firstName'],
            'customerLastName': customerDetails['lastName'],
            'customerPhone': customerDetails['phone'],
            'customerAddress': customerDetails['address'],
            'customerCity': customerDetails['city'],
            'customerCountry': customerDetails['country'],
            'deliveryType': 'Takeaway',
            'currency': currency,
            'totalAmount': totalAmount,
            'items': orderItems,
            'status': 'Pending',
            'paymentStatus': 'Paid',
            'paymentMethod': 'Card',
            'source': 'student_app',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _showSuccessDialog(orderNumber, currency);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save order: $e')));
      }
    }
  }

  Future<void> _startPayHereCheckout() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final String userId = user?.uid ?? 'TEST_STUDENT_001';
    
    debugPrint("--- PAYHERE CHECKOUT START ---");
    debugPrint("User ID: $userId (isGuest: ${user == null})");
    debugPrint("Merchant ID: '$_payHereMerchantId'");
    debugPrint("Sandbox Mode: $_payHereSandbox");
    debugPrint("Notify URL Configured: $_isPayHereNotifyUrlConfigured");

    if (!_isPayHereNotifyUrlConfigured && _payHereMerchantId.trim().isNotEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment service is not fully configured.')),
      );
      return;
    }

    if (_hasMixedCurrencies) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cannot checkout items with different currencies.'),
        ),
      );
      return;
    }

    final String orderId = 'FOOD-${DateTime.now().millisecondsSinceEpoch}';
    final String orderNumber = '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final double amount = totalPrice;
    final String currency = _checkoutCurrency;

    final orderItems = cart.entries.map((entry) {
      final item = menuItems.firstWhere((e) => e.id == entry.key);
      return {
        'id': item.id,
        'name': item.name,
        'quantity': entry.value,
        'unitPrice': item.price,
        'lineTotal': item.price * entry.value,
        'preparationMinutes': item.preparationMinutes,
      };
    }).toList();


    final customerDetails = await _resolvePayHereCustomerDetails();
    final paymentObject = _buildPayHerePaymentObject(
      orderId: orderId,
      orderNumber: orderNumber,
      totalAmount: amount,
      currency: currency,
      customerDetails: customerDetails,
    );

    final useSavedCard = _selectedCardMode == 'saved' &&
        _savedCardToken != null &&
        _savedCardToken!.trim().isNotEmpty;

    try {
      bool isCompleted = false;
      
      Future<void> onCompleted(String paymentId) async {
        isCompleted = true;
        await _finalizePaidOrder(
          paymentId: paymentId,
          orderId: orderId,
          orderNumber: orderNumber,
          currency: currency,
          totalAmount: amount,
          orderItems: orderItems,
          customerDetails: customerDetails,
        ).then((_) {
          if (mounted) {
            setState(() => _isPlacingOrder = false);
          }
        });
      }

      void onError(dynamic error) {
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          messenger.showSnackBar(SnackBar(content: Text('Payment failed: $error')));
        }
      }

      void onDismissed() {
        if (isCompleted) return; // Ignore if we already finished successfully
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          messenger.showSnackBar(
            const SnackBar(content: Text('Payment was dismissed.')),
          );
        }
      }

      if (_payHereMerchantId.trim().isEmpty) {
        PayHereSimulator.show(
          context,
          orderId: orderId,
          amount: amount,
          currency: currency,
          itemName: 'Food Order - $orderNumber',
          savedCardMask: _savedCardMask,
          onPaymentSuccess: onCompleted,
          onDismissed: onDismissed,
        );
        return;
      }

      if (useSavedCard) {
        final savedCardObject = Map<String, dynamic>.from(paymentObject)
          ..['customer_token'] = _savedCardToken
          ..['recurrence'] = 'Once';

        PayHere.startPayment(
          savedCardObject,
          onCompleted,
          onError,
          onDismissed,
        );
      } else {
        if (_payHereMerchantId.trim().isEmpty) {
          PayHereSimulator.show(
            context,
            orderId: orderId,
            amount: amount,
            currency: currency,
            itemName: 'Food Order - $orderNumber',
            isOneTap: false,
            onPaymentSuccess: onCompleted,
            onDismissed: onDismissed,
          );

          return;
        }
        PayHere.startPayment(paymentObject, onCompleted, onError, onDismissed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to open checkout: $e')));
      }
    }
  }

  Widget _buildCartButton(
    IconData icon,
    VoidCallback onTap,
    Color bgColor,
    Color iconColor,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }

  Future<void> _openMenuItemDetail(MenuItem item) async {
    final result = await Navigator.push<_FoodDetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _FoodDetailPage(
          item: item,
          initialQuantity: max(1, cart[item.id] ?? 1),
          formatPrice: _formatPrice,
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    if (result.quantity <= 0) {
      setState(() => cart.remove(item.id));
      return;
    }

    setState(() => cart[item.id] = min(result.quantity, item.quantity));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${cart[item.id]} x ${item.name} added to cart.')),
    );

    if (result.checkoutNow) {
      _showPaymentGateway();
    }
  }

  void _showPaymentGateway() {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: colors.border),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Checkout Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selection UI
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 20, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Checkout',
                                style: TextStyle(color: colors.foreground, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _savedCardMask != null 
                                  ? 'Pay with $_savedCardMask or use a new card'
                                  : 'Enter your card details in the next step',
                                style: TextStyle(color: colors.mutedForeground, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Items',
                              style: TextStyle(color: colors.mutedForeground),
                            ),
                            Text(
                              '${cart.values.fold(0, (sum, q) => sum + q)}',
                              style: TextStyle(
                                color: colors.foreground,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Grand Total',
                              style: TextStyle(color: colors.mutedForeground),
                            ),
                            Text(
                              _formatPrice(totalPrice, _checkoutCurrency),
                              style: TextStyle(
                                color: colors.foreground,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isPlacingOrder || _hasMixedCurrencies
                          ? null
                          : () async {
                              Navigator.pop(sheetContext);
                              await _startPayHereCheckout();
                            },
                      icon: const Icon(LucideIcons.checkCircle2, size: 20),
                      label: const Text(
                        'Confirm & Pay',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String orderNumber, String currency) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        alignment: Alignment.center,
        children: [
          Lottie.network(
            'https://assets1.lottiefiles.com/packages/lf20_u4yrau.json', // Confetti
            repeat: false,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.campusEmerald.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.checkCircle2,
                    color: colors.campusEmerald,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your order #$orderNumber for ${_formatPrice(totalPrice, currency)} has been placed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      GlobalState.foodOrderDetails.value =
                          '$totalItems items from ${widget.shop.name}';
                      GlobalState.foodOrderStatus.value = 'Pending';
                      Navigator.pop(context);
                      setState(() => cart.clear());
                    },
                    child: Text(
                      'Back to Menu',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_menuLoading && menuItems.isEmpty) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    if (!_menuLoading && menuItems.isEmpty) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: colors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Menu Unavailable', style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w800, fontSize: 16)),
          backgroundColor: colors.background,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.frown, size: 48, color: colors.mutedForeground),
                const SizedBox(height: 16),
                Text(
                  'No menu items available for ${widget.shop.name} right now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.mutedForeground, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categories = <String>{'All', ...menuItems.map((e) => e.category)}.toList();
    final filteredByCategory = selectedCategory == 'All' ? menuItems : menuItems.where((item) => item.category == selectedCategory).toList();
    final visibleItems = _searchQuery.trim().isEmpty
        ? filteredByCategory
        : filteredByCategory.where((item) => item.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()) || item.description.toLowerCase().contains(_searchQuery.trim().toLowerCase())).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // 1. MESH BACKGROUND (CONSISTENT WITH CAFETERIA PAGE)
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [colors.primary.withValues(alpha: 0.08), colors.primary.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, totalItems > 0 ? 120 : 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _iconCircleButton(icon: LucideIcons.arrowLeft, onTap: () => Navigator.pop(context)),
                                      Flexible(
                                        child: Hero(
                                          tag: 'shop_name_${widget.shop.id}',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.primary.withValues(alpha: 0.1))),
                                              child: Text(
                                                widget.shop.name.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MENU',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover the best\nflavors today',
                    style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 32, height: 1.1, letterSpacing: -1.0),
                  ),
                  const SizedBox(height: 24),
                  /* PREMIUM SEARCH SECTION */
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(LucideIcons.search, size: 20, color: colors.primary.withValues(alpha: 0.6)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                onChanged: (value) => setState(() => _searchQuery = value),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.foreground, letterSpacing: -0.2),
                                decoration: InputDecoration(
                                  hintText: 'Search flavors...',
                                  hintStyle: TextStyle(fontSize: 14, color: colors.mutedForeground, fontWeight: FontWeight.w500),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(LucideIcons.slidersHorizontal, size: 16, color: colors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  /* CATEGORIES */
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => selectedCategory = category);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? colors.primary : colors.card,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : colors.foreground),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.foreground)),
                      const Spacer(),
                      Text('${visibleItems.length} items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.mutedForeground)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  /* MENU GRID */
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleItems.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      final qty = cart[item.id] ?? 0;

                      return InkWell(
                        onTap: () => _openMenuItemDetail(item),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 100, height: 100,
                                    decoration: BoxDecoration(color: colors.background, shape: BoxShape.circle),
                                    child: ClipOval(
                                      child: item.imagePath != null && item.imagePath!.startsWith('http')
                                          ? Image.network(item.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(item.emoji, style: const TextStyle(fontSize: 40))))
                                          : Center(child: Text(item.emoji, style: const TextStyle(fontSize: 40))),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colors.foreground)),
                              const SizedBox(height: 2),
                              Text(item.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(_formatPrice(item.price, item.currency), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colors.primary)),
                                  const Spacer(),
                                  if (qty > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text('x$qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colors.primary)),
                                    )
                                  else
                                    Icon(LucideIcons.plusCircle, size: 18, color: colors.primary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            /* FLOATING CHECKOUT BAR */
            if (totalItems > 0)
              Positioned(
                left: 20, right: 20, bottom: 20,
                child: SafeArea(
                  top: false,
                  child: ValueListenableBuilder<String>(
                    valueListenable: GlobalState.foodOrderStatus,
                    builder: (context, status, _) {
                      final hasActiveOrder = (status == 'Pending' || status == 'Preparing' || status == 'Ready');
                      return GestureDetector(
                        onTap: () {
                          if (hasActiveOrder) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You already have an active order.')));
                          } else {
                            _showPaymentGateway();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: hasActiveOrder ? colors.muted : colors.primary,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [BoxShadow(color: (hasActiveOrder ? Colors.black : colors.primary).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.shoppingBag, color: hasActiveOrder ? colors.mutedForeground : Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CHECKOUT', style: TextStyle(color: (hasActiveOrder ? colors.mutedForeground : Colors.white).withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                    Text(_formatPrice(totalPrice, _checkoutCurrency), style: TextStyle(color: hasActiveOrder ? colors.mutedForeground : Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: (hasActiveOrder ? colors.mutedForeground : Colors.white).withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: Center(child: Text('$totalItems', style: TextStyle(color: hasActiveOrder ? colors.mutedForeground : Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

  Widget _iconCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: colors.foreground,
        ),
      ),
    );
  }
}

class _FoodDetailResult {
  final int quantity;
  final bool checkoutNow;

  const _FoodDetailResult({required this.quantity, required this.checkoutNow});
}

class _FoodDetailPage extends StatefulWidget {
  final MenuItem item;
  final int initialQuantity;
  final String Function(double amount, String currencyCode) formatPrice;

  const _FoodDetailPage({
    required this.item,
    required this.initialQuantity,
    required this.formatPrice,
  });

  @override
  State<_FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<_FoodDetailPage> {
  late int qty;

  @override
  void initState() {
    super.initState();
    qty = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final item = widget.item;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconCircleButton(
                    icon: LucideIcons.arrowLeft,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.flame, color: colors.primary, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFECECEC),
                      width: 2,
                    ),
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child:
                        item.imagePath != null &&
                            item.imagePath!.startsWith('http')
                        ? Image.network(
                            item.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Text(
                                    item.emoji,
                                    style: const TextStyle(fontSize: 76),
                                  ),
                                ),
                          )
                        : Center(
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 76),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 108,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (qty > 1) setState(() => qty--);
                        },
                        child: const Icon(
                          LucideIcons.minus,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '$qty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (qty < item.quantity) setState(() => qty++);
                        },
                        child: const Icon(
                          LucideIcons.plus,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF131313),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description.isEmpty
                    ? 'Fresh greens, premium toppings and balanced campus flavor in every bite.'
                    : item.description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF7C7C7C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 14,
                    color: Color(0xFFF6B40A),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '4.5',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 18),
                  const Icon(
                    LucideIcons.flame,
                    size: 14,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${80 + item.preparationMinutes} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 18),
                  const Icon(
                    LucideIcons.clock3,
                    size: 14,
                    color: Color(0xFF111111),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.preparationMinutes} min',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF242424),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  _IngredientBubble(icon: LucideIcons.leaf),
                  SizedBox(width: 8),
                  _IngredientBubble(icon: LucideIcons.apple),
                  SizedBox(width: 8),
                  _IngredientBubble(icon: Icons.eco),
                  SizedBox(width: 8),
                  _IngredientBubble(icon: Icons.local_florist),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A8A8A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.formatPrice(item.price * qty, item.currency),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _FoodDetailResult(
                              quantity: qty,
                              checkoutNow: false,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(LucideIcons.shoppingBag, size: 18),
                        label: const Text(
                          'Add To Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(
                        context,
                        _FoodDetailResult(quantity: qty, checkoutNow: true),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(
                        LucideIcons.creditCard,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: colors.foreground,
        ),
      ),
    );
  }
}

class _IngredientBubble extends StatelessWidget {
  final IconData icon;

  const _IngredientBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Icon(icon, size: 14, color: const Color(0xFF777777)),
    );
  }
}
class _PulsingIndicator extends StatefulWidget {
  final Color color;
  const _PulsingIndicator({required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 1.0 - _controller.value),
                blurRadius: 8 * _controller.value,
                spreadRadius: 4 * _controller.value,
              )
            ],
          ),
        );
      },
    );
  }
}
