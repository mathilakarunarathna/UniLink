import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _hasNavigated = false;
  Timer? _autoNavTimer;
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleAutoNavigation();
    });
  }

  Future<void> _scheduleAutoNavigation() async {
    _autoNavTimer?.cancel();

    // 1. Initial Check for Persistent Session
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. Refresh Profile Status from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          if (doc.exists && doc.data()?['onboarded'] == true) {
            // Already logged in and completed profile
            _autoNavTarget = '/dashboard';
          } else {
            // Logged in but profile incomplete
            _autoNavTarget = '/profile_completion';
          }
        }
      }
    } catch (_) {
      // Fallback to login on error
      _autoNavTarget = '/login';
    } finally {
      if (mounted) setState(() => _isLoadingSession = false);
    }

    // 3. Dispatch Navigation Timer
    _autoNavTimer = Timer(
      const Duration(milliseconds: 2400),
      _dispatchNavigation,
    );
  }

  String _autoNavTarget = '/login';

  void _dispatchNavigation() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacementNamed(_autoNavTarget);
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoNavTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isSmall = MediaQuery.of(context).size.width < 370;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _PremiumBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Center(child: _UniLinkHeroIllustration()),
                      const SizedBox(height: 32),
                      Text(
                        'UniLink',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: isSmall ? 40 : 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Everything you need on campus in one place.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Events • Study Spaces • Cafeteria • Payments',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(flex: 2),
                      Text(
                        _isLoadingSession
                            ? 'Securing session...'
                            : (_autoNavTarget == '/dashboard'
                                  ? 'Welcome back!'
                                  : 'Redirecting to login...'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isLoadingSession && _autoNavTarget == '/login')
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF310B5C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Continue with Google'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBackdrop extends StatelessWidget {
  const _PremiumBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.7, 1.0],
          colors: [
            Color(0xFF310B5C), // Deep Indigo
            Color(0xFF1A0730), // Darker transition
            Colors.black, // Total black bottom
          ],
        ),
      ),
    );
  }
}

class _UniLinkHeroIllustration extends StatelessWidget {
  const _UniLinkHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Aura Glow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Orbit/Wave Lines
          Positioned(
            bottom: 40,
            child: CustomPaint(
              size: const Size(200, 60),
              painter: _OrbitPainter(),
            ),
          ),

          // Icon Stack
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Person Circle
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1F1F1F),
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              // Laptop Box
              Container(
                width: 86,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF131313),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.laptop_chromebook_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path1 = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.2,
        size.width,
        size.height * 0.2,
      );

    final path2 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.4,
        size.width * 0.9,
        size.height * 0.5,
      );

    // Draw main orbit
    paint.color = const Color(0xFFDCCEFF).withValues(alpha: 0.4);
    glowPaint.color = const Color(0xFFDCCEFF).withValues(alpha: 0.1);
    canvas.drawPath(path1, glowPaint);
    canvas.drawPath(path1, paint);

    // Draw second orbit
    paint.color = const Color(0xFFDCCEFF).withValues(alpha: 0.2);
    glowPaint.color = const Color(0xFFDCCEFF).withValues(alpha: 0.05);
    canvas.drawPath(path2, glowPaint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
