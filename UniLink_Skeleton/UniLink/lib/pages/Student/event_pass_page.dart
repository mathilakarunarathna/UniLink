import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/mesh_gradient_background.dart';
import '../../data/global_state.dart';
import '../../models/campus_event.dart';
import '../../widgets/payhere_simulator.dart';
import '../../core/services/payment_service.dart';
import 'package:intl/intl.dart';

class EventPassPage extends StatefulWidget {
  const EventPassPage({super.key});

  @override
  State<EventPassPage> createState() => _EventPassPageState();
}

class _EventPassPageState extends State<EventPassPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _tapCount = 0;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _seedEventsIfNeeded();
  }

  Future<void> _seedEventsIfNeeded() async {
    final docs = await _firestore.collection('events').limit(1).get();
    if (docs.docs.isEmpty) {
      final batch = _firestore.batch();
      final items = [
        {
          'name': 'Techno Night 2026',
          'category': 'Music',
          'date': DateTime.now().add(const Duration(days: 14)),
          'location': 'Grand Arena',
          'price': 2500.0,
          'colorValue': 0xFF8B5CF6,
          'imageUrl': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745',
        },
        {
          'name': 'Hackathon: CodeX',
          'category': 'Tech',
          'date': DateTime.now().add(const Duration(days: 21)),
          'location': 'Innovation Hub',
          'price': 1500.0,
          'colorValue': 0xFF10B981,
          'imageUrl': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
        },
        {
          'name': 'Grand Awurudu Uthsawaya',
          'category': 'Culture',
          'date': DateTime.now().add(const Duration(days: 5)),
          'location': 'Main Grounds',
          'price': 500.0,
          'colorValue': 0xFFF59E0B,
          'imageUrl': 'https://images.unsplash.com/photo-1532375810709-7cc7190d6874',
        },
        {
          'name': 'Campus Cricket League',
          'category': 'Sports',
          'date': DateTime.now().add(const Duration(days: 10)),
          'location': 'University Oval',
          'price': 200.0,
          'colorValue': 0xFF3B82F6,
          'imageUrl': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da',
        },
        {
          'name': 'Art & Soul Exhibition',
          'category': 'Culture',
          'date': DateTime.now().add(const Duration(days: 30)),
          'location': 'Art Gallery',
          'price': 0.0,
          'colorValue': 0xFFEC4899,
          'imageUrl': 'https://images.unsplash.com/photo-1460661419201-fd4cecea8f82',
        },
        {
          'name': 'Future of AI Seminar',
          'category': 'Tech',
          'date': DateTime.now().add(const Duration(days: 2)),
          'location': 'Hall 01',
          'price': 0.0,
          'colorValue': 0xFF06B6D4,
          'imageUrl': 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e',
        },
      ];

      for (var item in items) {
        final ref = _firestore.collection('events').doc();
        batch.set(ref, {
          ...item,
          'date': Timestamp.fromDate(item['date'] as DateTime),
          'totalTickets': 500,
          'availableTickets': 500,
          'description': 'Experience the elite campus lifestyle.',
        });
      }
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = _auth.currentUser;
    final userId = user?.uid ?? 'TEST_STUDENT_001';

    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: const BottomNavBar(currentRoute: '/eventpass'),
      body: MeshGradientBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('tickets')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, ticketSnapshot) {
              final tickets = (ticketSnapshot.data?.docs ?? [])
                  .map((doc) => EventTicket.fromFirestore(doc))
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('events')
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.hasError) {
                    return Center(child: Text('Error: ${eventSnapshot.error}'));
                  }
                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allEventsFromFirestore = (eventSnapshot.data?.docs ?? [])
                      .map((doc) => CampusEvent.fromFirestore(doc))
                      .toList();

                  // MOCK EVENTS TO ENSURE UI IS ALWAYS FULL
                  final mockEvents = [
                    CampusEvent(
                      id: 'mock_1',
                      name: 'Techno Night: Neon Pulse',
                      category: 'Music',
                      date: DateTime.now().add(const Duration(days: 14)),
                      location: 'University Arena',
                      price: 2500.0,
                      colorValue: 0xFF8B5CF6,
                      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745',
                    ),
                    CampusEvent(
                      id: 'mock_2',
                      name: 'Jazz & Soul Evening',
                      category: 'Music',
                      date: DateTime.now().add(const Duration(days: 5)),
                      location: 'Arts Block',
                      price: 1000.0,
                      colorValue: 0xFFEC4899,
                      imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4',
                    ),
                    CampusEvent(
                      id: 'mock_3',
                      name: 'Hackathon: CodeX 2026',
                      category: 'Tech',
                      date: DateTime.now().add(const Duration(days: 21)),
                      location: 'Innovation Hub',
                      price: 1500.0,
                      colorValue: 0xFF10B981,
                      imageUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
                    ),
                    CampusEvent(
                      id: 'mock_4',
                      name: 'AI & Future Workshop',
                      category: 'Tech',
                      date: DateTime.now().add(const Duration(days: 2)),
                      location: 'Hall A',
                      price: 0.0,
                      colorValue: 0xFF06B6D4,
                      imageUrl: 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e',
                    ),
                    CampusEvent(
                      id: 'mock_5',
                      name: 'Grand Awurudu Uthsawaya',
                      category: 'Culture',
                      date: DateTime.now().add(const Duration(days: 10)),
                      location: 'Main Grounds',
                      price: 500.0,
                      colorValue: 0xFFF59E0B,
                      imageUrl: 'https://images.unsplash.com/photo-1532375810709-7cc7190d6874',
                    ),
                    CampusEvent(
                      id: 'mock_6',
                      name: 'Vesak Lantern Challenge',
                      category: 'Culture',
                      date: DateTime.now().add(const Duration(days: 30)),
                      location: 'Central Lake',
                      price: 0.0,
                      colorValue: 0xFFF97316,
                      imageUrl: 'https://images.unsplash.com/photo-1532372573130-1c0903332501',
                    ),
                    CampusEvent(
                      id: 'mock_7',
                      name: 'Campus Cricket Finals',
                      category: 'Sports',
                      date: DateTime.now().add(const Duration(days: 12)),
                      location: 'University Oval',
                      price: 200.0,
                      colorValue: 0xFF3B82F6,
                      imageUrl: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da',
                    ),
                    CampusEvent(
                      id: 'mock_8',
                      name: 'Table Tennis Open',
                      category: 'Sports',
                      date: DateTime.now().add(const Duration(days: 4)),
                      location: 'Indoor Gym',
                      price: 0.0,
                      colorValue: 0xFFEF4444,
                      imageUrl: 'https://images.unsplash.com/photo-1534067783941-51c9c23ecefd',
                    ),
                  ];

                  // COMBINE LIVE DATA WITH MOCK DATA
                  final allEvents = [...allEventsFromFirestore, ...mockEvents];

                  final ownedEventIds = tickets.map((t) => t.eventId).toSet();
                  final myUpcomingTickets = tickets.where((t) => t.status == 'active').toList();
                  
                  final filteredEvents = allEvents
                      .where((e) => !ownedEventIds.contains(e.id))
                      .where((e) => _selectedCategory == 'All' || e.category == _selectedCategory)
                      .toList();

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, colors),
                        
                        Padding(
                          padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
                          child: Text(
                            'My Passes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: colors.foreground,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildTicketsList(myUpcomingTickets, colors),

                        const SizedBox(height: 32),
                        _CategoryFilters(
                          selected: _selectedCategory,
                          onSelected: (cat) => setState(() => _selectedCategory = cat),
                        ),

                        if (filteredEvents.isNotEmpty) ...[
                          _buildUpcomingEvents(filteredEvents, colors),
                        ] else if (allEvents.isEmpty)
                          _buildEmptyState(colors)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No events in this category.",
                                style: TextStyle(color: colors.mutedForeground, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppCustomColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.arrowLeft, color: colors.foreground, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              const _PulsingLiveBadge(),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              _tapCount++;
              if (_tapCount >= 3) {
                _tapCount = 0;
                Navigator.pushNamed(context, '/admin/events');
              }
              Timer(const Duration(seconds: 2), () => _tapCount = 0);
            },
            child: Text(
              'Campus EventPass',
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your Passport to\nCampus Life',
            style: TextStyle(
              color: colors.foreground,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList(List<EventTicket> tickets, AppCustomColors colors) {
    if (tickets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.ticket, size: 40, color: colors.foreground.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Passes',
                    style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your campus tickets will appear here\nonce you discover more events.',
                    style: TextStyle(color: colors.mutedForeground, fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220, // Increased height to prevent overflow
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tickets.length,
        itemBuilder: (context, index) => _GlassTicketCard(ticket: tickets[index]),
      ),
    );
  }

  Widget _buildUpcomingEvents(List<CampusEvent> events, AppCustomColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _GlassEventTile(event: event),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppCustomColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(LucideIcons.calendarX, size: 48, color: colors.foreground.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No Events Available',
            style: TextStyle(color: colors.mutedForeground, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  static Widget _smartImage({
    required BuildContext context,
    String? url,
    required Color fallbackColor,
    required IconData fallbackIcon,
  }) {
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: Colors.white.withValues(alpha: 0.1));
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: fallbackColor.withValues(alpha: 0.15),
          child: Center(child: Icon(fallbackIcon, color: fallbackColor, size: 24)),
        ),
      );
    }
    return Container(
      color: fallbackColor.withValues(alpha: 0.15),
      child: Center(child: Icon(fallbackIcon, color: fallbackColor, size: 24)),
    );
  }

  Future<void> _handlePurchase(CampusEvent event, AppCustomColors colors) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final paymentService = PaymentService();
    final cardDetails = await paymentService.getSavedCardDetails();

    if (!mounted) return;

    PayHereSimulator.show(
      context,
      amount: event.price,
      currency: "LKR",
      orderId: "EVENT-${DateTime.now().millisecondsSinceEpoch}",
      itemName: "Ticket: ${event.name}",
      savedCardMask: cardDetails['savedCardMask'],
      onPaymentSuccess: (paymentId) async {
        final ticketNumber = "TKT-${Random().nextInt(90000) + 10000}";
        final newTicket = EventTicket(
          id: '',
          eventId: event.id,
          userId: user.uid,
          eventName: event.name,
          eventDate: event.date,
          eventLocation: event.location,
          eventColorValue: event.colorValue,
          ticketNumber: ticketNumber,
          purchaseDate: DateTime.now(),
          status: 'active',
          qrData: "UNILINK-TICKET-${event.id}-${user.uid}-$ticketNumber",
          eventImageUrl: event.imageUrl,
        );

        final batch = _firestore.batch();
        final ticketRef = _firestore.collection('tickets').doc();
        final eventRef = _firestore.collection('events').doc(event.id);

        batch.set(ticketRef, newTicket.toFirestore());
        batch.update(eventRef, {
          'availableTickets': FieldValue.increment(-1),
        });

        await batch.commit();

        GlobalState.ticketCount.value += 1;
        
        if (mounted) {
          _showSuccessDialog(event);
        }
      },
      onDismissed: () {},
    );
  }

  void _showSuccessDialog(CampusEvent event) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colors.card,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            Text(
              'Ticket Confirmed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.foreground),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ticket for ${event.name} has been added to My Tickets.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.mutedForeground),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Great!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  final String selected;
  final Function(String) onSelected;
  const _CategoryFilters({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Music', 'Tech', 'Culture', 'Sports'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Text('Explore Categories', style: TextStyle(color: AppColors.of(context).mutedForeground, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selected == cat;
              return GestureDetector(
                onTap: () => onSelected(cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.of(context).primary : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(color: isSelected ? Colors.white : AppColors.of(context).foreground, fontSize: 13, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PulsingLiveBadge extends StatefulWidget {
  const _PulsingLiveBadge();

  @override
  State<_PulsingLiveBadge> createState() => _PulsingLiveBadgeState();
}

class _PulsingLiveBadgeState extends State<_PulsingLiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE SYNC',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _GlassTicketCard extends StatelessWidget {
  final EventTicket ticket;
  const _GlassTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(ticket.eventColorValue);

    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Base Background (Image or Fallback)
            Positioned.fill(
              child: (ticket.eventImageUrl != null)
                ? _EventPassPageState._smartImage(
                    context: context,
                    url: ticket.eventImageUrl,
                    fallbackColor: themeColor,
                    fallbackIcon: LucideIcons.ticket,
                  )
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('events').doc(ticket.eventId).snapshots(),
                    builder: (context, snapshot) {
                      final imageUrl = (snapshot.data?.data() as Map<String, dynamic>?)?['imageUrl'];
                      return _EventPassPageState._smartImage(
                        context: context,
                        url: imageUrl,
                        fallbackColor: themeColor,
                        fallbackIcon: LucideIcons.ticket,
                      );
                    },
                  ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeColor.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.1, 0.4, 0.6, 0.9],
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.blueAccent.withValues(alpha: 0.05),
                        Colors.purpleAccent.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'OFFICIAL PASS',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                      ),
                      Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    ticket.eventName,
                    maxLines: 1, // Reduced to 1 to save space
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 10, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(ticket.eventLocation, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HOLDER TICKET ID', style: TextStyle(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          Text(ticket.ticketNumber, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15)],
                        ),
                        child: const Icon(LucideIcons.qrCode, color: Colors.black, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassEventTile extends StatelessWidget {
  final CampusEvent event;
  const _GlassEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeColor = Color(event.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: _EventPassPageState._smartImage(
                      context: context,
                      url: event.imageUrl,
                      fallbackColor: themeColor,
                      fallbackIcon: LucideIcons.calendar,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: TextStyle(color: themeColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.name,
                        style: TextStyle(color: colors.foreground, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('MMM dd').format(event.date)} • ${event.location}',
                        style: TextStyle(color: colors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final state = context.findAncestorStateOfType<_EventPassPageState>();
                        state?._handlePurchase(event, colors);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.primaryForeground,
                        elevation: 4,
                        shadowColor: colors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: Text(
                        'LKR ${event.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
