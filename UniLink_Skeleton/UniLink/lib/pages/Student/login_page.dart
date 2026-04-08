import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Check if profile is completed
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['onboarded'] == true) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        if (mounted)
          Navigator.of(context).pushReplacementNamed('/profile_completion');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
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
                    'UniLink Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 36 : 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use your university Google account to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF310B5C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF310B5C),
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, color: Color(0xFF310B5C)),
                                SizedBox(width: 14),
                                Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
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
                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
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
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: const [
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
    paint.color = const Color(0xFFDCCEFF).withOpacity(0.4);
    glowPaint.color = const Color(0xFFDCCEFF).withOpacity(0.1);
    canvas.drawPath(path1, glowPaint);
    canvas.drawPath(path1, paint);

    // Draw second orbit
    paint.color = const Color(0xFFDCCEFF).withOpacity(0.2);
    glowPaint.color = const Color(0xFFDCCEFF).withOpacity(0.05);
    canvas.drawPath(path2, glowPaint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _MicrosoftLogo extends StatelessWidget {
  const _MicrosoftLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(color: const Color(0xFFF25022))),
                const SizedBox(width: 1.5),
                Expanded(child: Container(color: const Color(0xFF7FBA00))),
              ],
            ),
          ),
          const SizedBox(height: 1.5),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(color: const Color(0xFF00A4EF))),
                const SizedBox(width: 1.5),
                Expanded(child: Container(color: const Color(0xFFFFB900))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
