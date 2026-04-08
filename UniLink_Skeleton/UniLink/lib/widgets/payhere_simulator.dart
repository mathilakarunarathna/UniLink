import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

class PayHereSimulator extends StatefulWidget {
  final String? setupLabel;
  final String? initialCardNumber;
  final Function(String cardLast4, String paymentId)? onCardSaved;
  final Function(String paymentId)? onPaymentSuccess;
  final bool isOneTap;
  final String? savedCardMask;
  final VoidCallback onDismissed;

  const PayHereSimulator({
    super.key,
    this.setupLabel,
    this.initialCardNumber,
    this.onCardSaved,
    this.onPaymentSuccess,
    this.isOneTap = false,
    this.savedCardMask,
    required this.onDismissed,
  });

  static void show(
    BuildContext context, {
    String? setupLabel,
    String? initialCardNumber,
    String? orderId,
    double? amount,
    String? currency,
    String? itemName,
    Function(String cardLast4, String paymentId)? onCardSaved,
    Function(String paymentId)? onPaymentSuccess,
    bool isOneTap = false,
    String? savedCardMask,
    required VoidCallback onDismissed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PayHereSimulator(
          setupLabel: setupLabel,
          initialCardNumber: initialCardNumber,
          onCardSaved: onCardSaved,
          onPaymentSuccess: onPaymentSuccess,
          isOneTap: isOneTap,
          savedCardMask: savedCardMask,
          onDismissed: onDismissed,
        );
      },
    ).then((result) {
      if (result != true) {
        onDismissed();
      }
    });

  }

  @override
  State<PayHereSimulator> createState() => _PayHereSimulatorState();
}

class _PayHereSimulatorState extends State<PayHereSimulator> {

  bool get isCardSavingMode => widget.onCardSaved != null;

  final TextEditingController _numberController = TextEditingController();

  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _isProcessing = false;
  bool _isSuccess = false;
  late bool _showDetailedForm;

  @override
  void initState() {
    super.initState();
    _showDetailedForm = widget.savedCardMask == null && !widget.isOneTap;
    _numberController.text = widget.initialCardNumber ?? '';
    _holderController.text = widget.setupLabel ?? 'Student User';
  }

  void _handleOneTapConfirm() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pop(context, true);
        if (widget.onPaymentSuccess != null) {
          widget.onPaymentSuccess!('ONE-TAP-PAY-${DateTime.now().millisecondsSinceEpoch}');
        }
      }

    }
  }

  void _handleSaveCard() async {

    final number = _numberController.text.replaceAll(' ', '');
    if (number.length < 16 || _expiryController.text.length < 5 || _cvvController.text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid card details')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate PayHere API card verification and pre-approval
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });

      // Brief success animation delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        final last4 = number.substring(number.length - 4);
        Navigator.pop(context, true);
        if (widget.onCardSaved != null) {
          widget.onCardSaved!(last4, 'PAY-PRE-${DateTime.now().millisecondsSinceEpoch}');
        } else if (widget.onPaymentSuccess != null) {
          widget.onPaymentSuccess!('PAY-${DateTime.now().millisecondsSinceEpoch}');
        }
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: Column(
          children: [
            // PayHere Style Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.creditCard, color: Color(0xFF001A72), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UniLink Pay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'SECURE ENCRYPTED STORAGE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
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
                    : (_isProcessing 
                        ? _buildProcessingView(colors) 
                        : (_showDetailedForm ? _buildCardForm(colors, isDark) : _buildOneTapView(colors, isDark))),

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
                    'SECURE ENCRYPTED STORAGE',
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

  Widget _buildOneTapView(AppCustomColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.zap, color: colors.primary, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Confirm One-Tap Payment',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Authorize this transaction using your saved card ending in ${widget.savedCardMask ?? "****"}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleOneTapConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Authorize Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() => _showDetailedForm = true);
            },
            child: Text(
              'Use another card',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel Transaction',
              style: TextStyle(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm(AppCustomColors colors, bool isDark) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter payment details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCardSavingMode
                ? 'Your card details will be stored securely for one-click student payments.'
                : 'Enter your card details to authorize this secure payment.',

            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _numberController.text = '4242 4242 4242 4242';
                _expiryController.text = '12/26';
                _cvvController.text = '123';
                _holderController.text = 'TEST STUDENT';
              });
            },
            icon: const Icon(LucideIcons.testTube, size: 14),
            label: const Text('Fill with Test Card'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: const Color(0xFF00B5E0),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            'Card Number', 
            _numberController, 
            LucideIcons.creditCard, 
            colors,
            placeholder: 'XXXX XXXX XXXX XXXX',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberInputFormatter(),
            ],
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            'Card Holder Name', 
            _holderController, 
            LucideIcons.user, 
            colors,
            placeholder: 'Name on card'
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Expiry Date', 
                  _expiryController, 
                  LucideIcons.calendar, 
                  colors,
                  placeholder: 'MM/YY',
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryDateInputFormatter(),
                  ],
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'CVV', 
                  _cvvController, 
                  LucideIcons.shield, 
                  colors,
                  placeholder: '123',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(3),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSaveCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001A72),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isCardSavingMode ? 'Authorize and Save Card' : 'Authorize Now',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.savedCardMask != null)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _showDetailedForm = false);
                },
                child: Text(
                  'Return to saved card',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel and return',
                style: TextStyle(color: colors.mutedForeground, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    AppCustomColors colors, {
    String? placeholder,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
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
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: colors.mutedForeground.withValues(alpha: 0.5), fontSize: 14),
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
              color: Color(0xFF00B5E0),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Securing your card details...',
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
            'Card Linked Successfully',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF001A72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your card is now saved for one-click payments.',
            textAlign: TextAlign.center,
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

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) text = text.substring(0, 4);

    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
        if (i == 2) buffer.write('/');
        buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length && index < 16; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
