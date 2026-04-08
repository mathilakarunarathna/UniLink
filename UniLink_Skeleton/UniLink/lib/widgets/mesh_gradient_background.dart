import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Stack(
      children: [
        // 1. BASE COLOR
        Positioned.fill(
          child: Container(color: colors.background),
        ),
        
        // 2. ANIMATED BLOBS
        const _AnimatedBlob(
          alignment: Alignment.topLeft,
          color: Color(0x337C3AED), // Violet
          size: 350,
        ),
        const _AnimatedBlob(
          alignment: Alignment.bottomRight,
          color: Color(0x223B82F6), // Blue
          size: 400,
        ),
        const _AnimatedBlob(
          alignment: Alignment.centerRight,
          color: Color(0x1F10B981), // Emerald
          size: 300,
        ),
        
        // 3. BACKDROP BLUR
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
        
        // 4. CONTENT
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AnimatedBlob extends StatefulWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _AnimatedBlob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignment;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _alignment = Tween<Alignment>(
      begin: widget.alignment,
      end: Alignment(
        widget.alignment.x * -0.8,
        widget.alignment.y * -0.6,
      ),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alignment,
      builder: (context, child) {
        return Align(
          alignment: _alignment.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
