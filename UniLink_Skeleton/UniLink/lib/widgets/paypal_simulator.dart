import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

class PayPalSimulator extends StatefulWidget {
  final String email;
  final Function(String email) onAccountLinked;
  final VoidCallback onDismissed;

  const PayPalSimulator({
    super.key,
    required this.email,
    required this.onAccountLinked,
    required this.onDismissed,
  });

  static void show(
    BuildContext context, {
    required String email,
    required Function(String accountEmail) onAccountLinked,
    required VoidCallback onDismissed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PayPalSimulator(
          email: email,
          onAccountLinked: onAccountLinked,
          onDismissed: onDismissed,
        );
      },
    ).then((_) {
      onDismissed();
    });
  }

  @override
  State<PayPalSimulator> createState() => _PayPalSimulatorState();
}

class _PayPalSimulatorState extends State<PayPalSimulator> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  void _handleLinkAccount() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your PayPal details')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate PayPal API verification delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });

      // Brief success animation delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        widget.onAccountLinked(_emailController.text.trim());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: Column(
          children: [
            // PayPal Style Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF003087), // PayPal Blue
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.wallet, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PayPal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            'Sandbox Environment',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isSuccess
                    ? _buildSuccessView(colors)
                    : (_isProcessing ? _buildProcessingView(colors) : _buildLoginForm(colors, isDark)),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.lock, size: 12, color: colors.mutedForeground),
                  const SizedBox(width: 8),
                  Text(
                    'SECURE PAYPAL CHECKOUT',
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(AppCustomColors colors, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Link your PayPal account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Linking your account allows for faster student cafeteria payments.',
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('Email address', _emailController, LucideIcons.mail, colors),
          const SizedBox(height: 20),
          _buildTextField('Password', _passwordController, LucideIcons.lock, colors, isObscure: true),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleLinkAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0070BA), // PayPal Active Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Log In and Link',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel and return to UniLink',
                style: TextStyle(color: colors.mutedForeground, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, AppCustomColors colors, {bool isObscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: colors.mutedForeground),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView(AppCustomColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Color(0xFF0070BA),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Verifying account details...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(AppCustomColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE6F9F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              color: Color(0xFF10B981),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Successfully Linked',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF003087),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your PayPal account is ready to use.',
            style: TextStyle(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
