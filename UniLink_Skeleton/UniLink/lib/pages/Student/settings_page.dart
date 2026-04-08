import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_notifier.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'contact_admin_page.dart';
import '../../widgets/paypal_simulator.dart';
import '../../widgets/payhere_simulator.dart';

// No palette class needed anymore. Using AppCustomColors extension.

const String _payHereMerchantId = String.fromEnvironment(
  'PAYHERE_MERCHANT_ID',
  defaultValue: '',
);
const String _payHereNotifyUrl = String.fromEnvironment(
  'PAYHERE_NOTIFY_URL',
  defaultValue:
      'https://your-domain.okexample.com/api/v1/cafeteria/payhere/notify',
);
const bool _payHereSandbox = true;
final bool _isPayHereNotifyUrlConfigured =
    _payHereNotifyUrl != '' && !_payHereNotifyUrl.contains('okexample.com');

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.openAddCardOnLoad = false});

  final bool openAddCardOnLoad;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _darkMode = Theme.of(context).brightness == Brightness.dark;
  }

  bool _locationSharing = false;
  bool _rememberCheckoutPreference = true;
  bool _receiptByEmail = true;
  bool _autoApplySavedCheckout = true;
  String _language = 'English';
  String? _savedCardMask;
  String _savedCardLabel = 'No Card Linked';
  bool _didOpenAddCardSheet = false;
  bool _isPayPalLinked = false;
  String? _linkedPayPalEmail;
  bool _biometricLogin = false;
  bool _twoFactorAuth = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentPreferences();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.openAddCardOnLoad || _didOpenAddCardSheet) {
        return;
      }
      _didOpenAddCardSheet = true;
      _showAddCardSheet(AppColors.of(context));
    });
  }

  Future<void> _loadPaymentPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final data = doc.data() ?? {};

      if (!mounted) return;
      setState(() {
        _rememberCheckoutPreference = data['saveCardForFutureOrders'] is bool
            ? data['saveCardForFutureOrders'] as bool
            : _rememberCheckoutPreference;
        _autoApplySavedCheckout = data['autoApplySavedCheckout'] is bool
            ? data['autoApplySavedCheckout'] as bool
            : _autoApplySavedCheckout;
        _receiptByEmail = data['receiptByEmail'] is bool
            ? data['receiptByEmail'] as bool
            : _receiptByEmail;

        _linkedPayPalEmail = data['paypalEmail'];
        _savedCardLabel = data['payhereCardLabel'] ?? 'No Card Linked';
        _savedCardMask = data['savedCardLast4'] != null
            ? '**** ${data['savedCardLast4']}'
            : null;

        // PayPal preferences
        _isPayPalLinked = data['paypalLinked'] == true;
        if (_linkedPayPalEmail?.isEmpty ?? true) {
          _linkedPayPalEmail = null;
        }

        // Security Preferences
        _biometricLogin = data['biometricLogin'] == true;
        _twoFactorAuth = data['twoFactorAuth'] == true;
      });
    } catch (_) {}
  }

  Future<void> _saveSettingsPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'saveCardForFutureOrders': _rememberCheckoutPreference,
      'autoApplySavedCheckout': _autoApplySavedCheckout,
      'receiptByEmail': _receiptByEmail,
      'biometricLogin': _biometricLogin,
      'twoFactorAuth': _twoFactorAuth,
      'preferredCheckoutGateway': _rememberCheckoutPreference
          ? 'Card Preapproval'
          : 'Card One-time',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> _startPayHereCardSetup({
    required BuildContext context,
    required String setupLabel,
    String? cardLast4,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;

    final String userId = user?.uid ?? 'TEST_STUDENT_001';

    debugPrint("--- PAYHERE SETUP START ---");
    debugPrint("User ID: $userId (isGuest: ${user == null})");
    debugPrint("Merchant ID: '$_payHereMerchantId'");
    debugPrint("Sandbox Mode: $_payHereSandbox");
    debugPrint("Notify URL Configured: $_isPayHereNotifyUrlConfigured");

    if (cardLast4 != null && cardLast4.trim().isNotEmpty) {
      // Direct save if card details were already obtained (legacy support or internal use)
      debugPrint("Directly saving card: $cardLast4");

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'payhereCardLabel': setupLabel,
        'payhereSavedCardEnabled': true,
        'payhereCustomerToken':
            'sandbox_${DateTime.now().millisecondsSinceEpoch}',
        'payhereTokenStatus': 'sandbox_simulated',
        'savedCardLast4': cardLast4.trim(),
        'payhereTokenUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _savedCardLabel = setupLabel;
          _savedCardMask = '**** ${cardLast4.trim()}';
        });
      }
      return true;
    }

    try {
      if (mounted) {
        setState(() {
          _savedCardLabel = setupLabel;
          _savedCardMask = (cardLast4 != null && cardLast4.trim().isNotEmpty)
              ? '**** ${cardLast4.trim()}'
              : null;
        });
      }

      bool isCompleted = false;

      Future<void> onCompleted(String paymentId, String last4) async {
        isCompleted = true;
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'payhereCardLabel': setupLabel,
          'payhereSavedCardEnabled': true,
          'payhereTokenStatus': 'pending',
          'savedCardLast4': last4.trim(),
          'payhereSetupPaymentId': paymentId,
          'payhereTokenUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        setState(() {
          _savedCardLabel = setupLabel;
          _savedCardMask = '**** ${last4.trim()}';
        });

        unawaited(_loadPaymentPreferences());
        messenger.showSnackBar(
          const SnackBar(content: Text('Card linked successfully.')),
        );
      }

      void onDismissed() {
        if (isCompleted) return; // Ignore if we already finished successfully

        if (!_isPayHereNotifyUrlConfigured &&
            _payHereMerchantId.trim().isNotEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment service is not fully configured.'),
            ),
          );
          return;
        }
        if (!mounted) return;
        unawaited(_loadPaymentPreferences());
        messenger.showSnackBar(
          const SnackBar(content: Text('Card setup was dismissed.')),
        );
      }

      // 2. Show simulator immediately for better responsiveness
      PayHereSimulator.show(
        context,
        setupLabel: setupLabel,
        initialCardNumber: null,
        onCardSaved: (last4, paymentId) => onCompleted(paymentId, last4),
        onDismissed: onDismissed,
      );

      // 3. Update status in background
      unawaited(
        FirebaseFirestore.instance.collection('users').doc(userId).set({
          'payhereCardLabel': setupLabel,
          'payhereSavedCardEnabled': true,
          'payhereTokenStatus': 'processing',
          'payhereTokenUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

      return true;
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Unable to open card setup: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _deleteSavedCard() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'payhereCustomerToken': FieldValue.delete(),
            'payhereCardLabel': FieldValue.delete(),
            'payhereSavedCardEnabled': false,
            'savedCardLast4': FieldValue.delete(),
            'payhereTokenStatus': FieldValue.delete(),
            'payhereSetupPaymentId': FieldValue.delete(),
            'payhereTokenUpdatedAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() {
          _savedCardMask = null;
          _savedCardLabel = 'No Card Linked';
        });

        messenger.showSnackBar(
          const SnackBar(content: Text('Card removed successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to remove card: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Card?'),
        content: const Text(
          'Are you sure you want to remove this saved card? You will need to re-add it for future one-tap payments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close wallet sheet
              _deleteSavedCard();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _startPayPalLinkFlow(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    PayPalSimulator.show(
      context,
      email: user?.email ?? '',
      onAccountLinked: (email) async {
        if (user?.uid == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({
              'paypalEmail': email,
              'paypalLinked': true,
              'paypalUpdatedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _linkedPayPalEmail = email;
            _isPayPalLinked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PayPal account linked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onDismissed: () {
        debugPrint("PayPal linking dismissed");
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'student@unilink.com';
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: const BottomNavBar(currentRoute: '/settings'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.background, theme.scaffoldBackgroundColor],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.campusTeal.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.white.withValues(alpha: 0.24)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.cardColor,
                          colors.background.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: colors.muted,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.arrowLeft),
                                color: colors.foreground,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CAMPUS IDENTITY',
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Account',
                                    style: TextStyle(
                                      color: colors.foreground,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Manage your profile and campus preferences',
                            style: TextStyle(
                              color: colors.foreground,
                              fontSize: 20,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Unified Profile Section
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid ?? 'unknown')
                        .snapshots(),
                    builder: (context, snapshot) {
                      String name = user?.displayName ?? "Student";
                      String email = user?.email ?? "guest@university.edu";
                      String phone = "Not set";
                      String program = "Not set";
                      String campus = "Not set";
                      String studentId = "Not set";

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        name = data['fullName'] ?? name;
                        phone = data['phone'] ?? phone;
                        program = data['program'] ?? program;
                        campus = data['campus'] ?? campus;
                        studentId = data['studentId'] ?? studentId;
                      }

                      final initial = name.isNotEmpty ? name[0] : "S";

                      return Column(
                        children: [
                          _buildProfileBanner(
                            initial,
                            name,
                            email,
                            studentId,
                            program,
                            colors,
                            theme,
                          ),
                          const SizedBox(height: 12),
                          _buildSectionTitle('Profile Information', colors),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  LucideIcons.phone,
                                  'Phone',
                                  phone,
                                  colors,
                                ),
                                const Divider(height: 24, thickness: 0.5),
                                _buildInfoRow(
                                  LucideIcons.graduationCap,
                                  'Program',
                                  program,
                                  colors,
                                ),
                                const Divider(height: 24, thickness: 0.5),
                                _buildInfoRow(
                                  LucideIcons.mapPin,
                                  'Campus',
                                  campus,
                                  colors,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Order Preferences', colors),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: LucideIcons.walletCards,
                    title: 'Remember card choice',
                    subtitle:
                        'Keep the saved checkout preference on this device',
                    value: _rememberCheckoutPreference,
                    onChanged: (value) {
                      setState(() => _rememberCheckoutPreference = value);
                      _saveSettingsPreferences();
                    },
                    colors: colors,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: LucideIcons.settings2,
                    title: 'Auto-apply saved checkout',
                    subtitle: 'Use your preferred payment flow automatically',
                    value: _autoApplySavedCheckout,
                    onChanged: (value) {
                      setState(() => _autoApplySavedCheckout = value);
                      _saveSettingsPreferences();
                    },
                    colors: colors,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: LucideIcons.mailOpen,
                    title: 'Receipt by email',
                    subtitle: 'Send order receipts to your student email',
                    value: _receiptByEmail,
                    onChanged: (value) {
                      setState(() => _receiptByEmail = value);
                      _saveSettingsPreferences();
                    },
                    colors: colors,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: LucideIcons.walletCards,
                    title: 'Payment Methods',
                    subtitle: 'Manage saved cards and payment options',
                    onTap: () => _showAddCardSheet(colors),
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Preferences', colors),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: LucideIcons.bell,
                    title: 'Notifications',
                    subtitle: 'Receive order and campus alerts',
                    value: _notifications,
                    onChanged: (value) =>
                        setState(() => _notifications = value),
                    colors: colors,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: LucideIcons.mapPin,
                    title: 'Location Sharing',
                    subtitle: 'Help services show nearby options',
                    value: _locationSharing,
                    onChanged: (value) =>
                        setState(() => _locationSharing = value),
                    colors: colors,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: LucideIcons.lock,
                    title: 'Security Center',
                    subtitle: 'Change password and manage sign-in safety',
                    onTap: () => _showSecurityCenterSheet(colors),
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('App', colors),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: LucideIcons.moon,
                    title: 'Dark Mode',
                    subtitle: 'Use a darker interface theme',
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      themeNotifier.value = value
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                    colors: colors,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: LucideIcons.languages,
                    title: 'Language',
                    subtitle: _language,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            border: Border.all(color: colors.border),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 52,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colors.mutedForeground.withValues(
                                        alpha: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Choose language',
                                  style: TextStyle(
                                    color: colors.foreground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...['English', 'සිංහල', 'தமிழ்'].map((value) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() => _language = value);
                                        Navigator.pop(context);
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _language == value
                                              ? colors.campusTeal.withValues(
                                                  alpha: 0.10,
                                                )
                                              : colors.background,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: _language == value
                                                ? colors.campusTeal.withValues(
                                                    alpha: 0.24,
                                                  )
                                                : colors.border,
                                          ),
                                        ),
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: colors.foreground,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Quick Actions', colors),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: LucideIcons.messageSquare,
                    title: 'Contact Admin',
                    subtitle: 'Open the support chat',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContactAdminPage(),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: LucideIcons.shield,
                    title: 'Privacy & Security',
                    subtitle: 'Review account security settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Privacy settings page coming soon.'),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: LucideIcons.helpCircle,
                    title: 'Help & Support',
                    subtitle: 'Get help with the app',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Help center will be added next.'),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: LucideIcons.info,
                    title: 'About UniLink',
                    subtitle: 'Version, policies, and campus app info',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            border: Border.all(color: colors.border),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 52,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colors.mutedForeground.withValues(
                                        alpha: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'UniLink',
                                  style: TextStyle(
                                    color: colors.foreground,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Campus management app for students',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildAboutRow('Version', '1.0.0', colors),
                                _buildAboutRow(
                                  'Platform',
                                  'Student App',
                                  colors,
                                ),
                                _buildAboutRow(
                                  'Mode',
                                  _darkMode ? 'Dark' : 'Light',
                                  colors,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _buildLogoutButton(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBanner(
    String initial,
    String name,
    String email,
    String studentId,
    String program,
    AppCustomColors colors,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _showEditProfileSheet(colors, name, studentId, program),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: colors.foreground.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Decorative Elements
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.campusTeal.withValues(alpha: 0.03),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.12),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.25), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: colors.foreground,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.campusEmerald.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.checkCircle2, size: 12, color: colors.campusEmerald),
                                      const SizedBox(width: 4),
                                      Text(
                                        'VERIFIED',
                                        style: TextStyle(
                                          color: colors.campusEmerald,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.muted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.fingerprint, size: 14, color: colors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    studentId,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIdentityDetail('DEPARTMENT', program.split(' ').first, colors),
                      _buildIdentityDetail('STATUS', 'ACTIVE', colors),
                      _buildIdentityDetail('EXPIRY', '2026/09', colors),
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

  Widget _buildIdentityDetail(String label, String value, AppCustomColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.mutedForeground.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            color: colors.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  void _showEditProfileSheet(AppCustomColors colors, String currentName, String currentId, String currentProgram) {
    final nameController = TextEditingController(text: currentName);
    final idController = TextEditingController(text: currentId == 'Not set' ? '' : currentId);
    final programController = TextEditingController(text: currentProgram == 'Not set' ? '' : currentProgram);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(sheetContext).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Personalize Profile',
              style: TextStyle(color: colors.foreground, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            _buildProfileTextField(LucideIcons.user, 'Full Name', nameController, colors),
            const SizedBox(height: 16),
            _buildProfileTextField(LucideIcons.fingerprint, 'Student ID', idController, colors),
            const SizedBox(height: 16),
            _buildProfileTextField(LucideIcons.graduationCap, 'Degree Program', programController, colors),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'fullName': nameController.text.trim(),
                      'studentId': idController.text.trim(),
                      'program': programController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTextField(IconData icon, String label, TextEditingController controller, AppCustomColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.mutedForeground, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: colors.foreground, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: colors.primary),
            filled: true,
            fillColor: colors.muted.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, AppCustomColors colors) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppCustomColors colors,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
            activeTrackColor: colors.primary.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppCustomColors colors,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: highlighted
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _darkMode
                      ? [colors.muted, colors.background]
                      : [const Color(0xFFFFFEFF), const Color(0xFFF7FAFF)],
                )
              : null,
          color: highlighted ? null : (Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted
                ? colors.primary.withValues(alpha: 0.14)
                : colors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: highlighted
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.foreground.withValues(alpha: 0.05),
              blurRadius: highlighted ? 18 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: highlighted
                    ? colors.primary.withValues(alpha: 0.10)
                    : colors.muted,
                borderRadius: BorderRadius.circular(14),
                border: highlighted
                    ? Border.all(color: colors.primary.withValues(alpha: 0.16))
                    : null,
              ),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value, AppCustomColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AppCustomColors colors) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(LucideIcons.logOut),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.destructive,
          side: BorderSide(color: colors.destructive.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showSecurityCenterSheet(AppCustomColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colors = AppColors.of(context);
            final theme = Theme.of(context);
            final Color sheetBg = theme.scaffoldBackgroundColor;
            final Color sheetText = colors.foreground;
            final Color sheetSubText = colors.mutedForeground;

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.shieldCheck, color: colors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Center',
                              style: TextStyle(
                                color: sheetText,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Manage your account safety',
                              style: TextStyle(
                                color: sheetSubText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSecuritySectionHeader('ACCOUNT ACCESS'),
                            const SizedBox(height: 12),
                            _buildSecurityActionTile(
                              icon: LucideIcons.keyRound,
                              title: 'Change Password',
                              subtitle: 'Update your login credentials',
                              onTap: () {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Verification email sent to reset password.')),
                                );
                              },
                              colors: colors,
                            ),
                            const SizedBox(height: 12),
                            _buildSecurityToggleTile(
                              icon: LucideIcons.shieldAlert,
                              title: 'Two-Factor Authentication',
                              subtitle: 'Add an extra layer of security',
                              value: _twoFactorAuth,
                              onChanged: (val) {
                                setModalState(() => _twoFactorAuth = val);
                                setState(() => _twoFactorAuth = val);
                                _saveSettingsPreferences();
                              },
                              colors: colors,
                            ),
                            const SizedBox(height: 32),
                            _buildSecuritySectionHeader('PRIVACY & BIOMETRICS'),
                            const SizedBox(height: 12),
                            _buildSecurityToggleTile(
                              icon: LucideIcons.fingerprint,
                              title: 'Biometric Login',
                              subtitle: 'Use FaceID or Fingerprint',
                              value: _biometricLogin,
                              onChanged: (val) {
                                setModalState(() => _biometricLogin = val);
                                setState(() => _biometricLogin = val);
                                _saveSettingsPreferences();
                              },
                              colors: colors,
                            ),
                            const SizedBox(height: 32),
                            _buildSecuritySectionHeader('ACTIVE SESSIONS'),
                            const SizedBox(height: 12),
                            _buildSessionTile(
                              device: 'iPhone 15 Pro (Current)',
                              location: 'Colombo, Sri Lanka',
                              time: 'Active now',
                              colors: colors,
                            ),
                            const SizedBox(height: 12),
                            _buildSessionTile(
                              device: 'Windows PC • Chrome',
                              location: 'University Library',
                              time: '2 hours ago',
                              colors: colors,
                              isOther: true,
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(foregroundColor: colors.destructive),
                              child: const Text('Sign out of all other devices', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSecuritySectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildSecurityActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppCustomColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.foreground, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(subtitle, style: TextStyle(color: colors.mutedForeground, fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: colors.mutedForeground, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppCustomColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.foreground, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: colors.mutedForeground, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile({
    required String device,
    required String location,
    required String time,
    required AppCustomColors colors,
    bool isOther = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(isOther ? LucideIcons.monitor : LucideIcons.smartphone, color: colors.mutedForeground, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('$location • $time', style: TextStyle(color: colors.mutedForeground, fontSize: 11)),
              ],
            ),
          ),
          if (isOther)
            IconButton(
              icon: Icon(LucideIcons.logOut, color: colors.destructive, size: 16),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  void _showAddCardSheet(AppCustomColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colors = AppColors.of(context);
            final theme = Theme.of(context);
            final Color sheetBg = theme.scaffoldBackgroundColor;
            final Color sheetText = colors.foreground;
            final Color sheetSubText = colors.mutedForeground;
            final Color fieldBorder = colors.border;

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.7,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: fieldBorder,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment',
                                style: TextStyle(
                                  color: sheetText,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Account Wallets',
                                style: TextStyle(
                                  color: sheetSubText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _savedCardMask == null && !_isPayPalLinked
                                ? 'No Accounts'
                                : ([
                                        if (_savedCardMask != null) 1,
                                        if (_isPayPalLinked) 1,
                                      ].length.toString() +
                                      ' Account' +
                                      ([
                                                if (_savedCardMask != null) 1,
                                                if (_isPayPalLinked) 1,
                                              ].length >
                                              1
                                          ? 's'
                                          : '') +
                                      ' Added'),
                            style: TextStyle(
                              color: sheetSubText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isPayPalLinked && _linkedPayPalEmail != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF003087,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFF003087,
                              ).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF003087),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.wallet,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PayPal Linked',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF003087),
                                      ),
                                    ),
                                    Text(
                                      _linkedPayPalEmail!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                LucideIcons.checkCircle2,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_savedCardMask != null) ...[
                            Container(
                              width: double.infinity,
                              height: 230, // Optimized height
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1A1C2E), // Deeper Sapphire
                                    const Color(0xFF13141F),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    // Abstract Pattern Overlay (Realistic card texture)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: 0.03,
                                        child: CustomPaint(
                                          painter: CardPatternPainter(),
                                        ),
                                      ),
                                    ),
                                    
                                    // Glossy Flare
                                    Positioned(
                                      top: -150,
                                      right: -100,
                                      child: Container(
                                        width: 300,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.white.withValues(alpha: 0.1),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Header: Bank Name & Delete Button
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(LucideIcons.landmark, color: colors.primary, size: 20),
                                                  const SizedBox(width: 10),
                                                  const Text(
                                                    'UniLink Student Bank',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Sleek Integrated Delete Button
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _showDeleteConfirmation(sheetContext),
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: Colors.white.withValues(alpha: 0.1),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      LucideIcons.trash2,
                                                      size: 16,
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // EMV Chip & Contactless
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                width: 46,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFF7D970), Color(0xFFC5A000)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 32,
                                                    height: 22,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.black26, width: 0.5),
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const Icon(LucideIcons.wifi, color: Colors.white70, size: 20),
                                            ],
                                          ),
                                          
                                          // Card Number (One Line - Optimized Font)
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              _savedCardMask!.replaceFirst('****', '****  ****  **** '),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 2,
                                                fontFamily: 'Courier',
                                                shadows: [
                                                  Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(1, 1), blurRadius: 1),
                                                  Shadow(color: Colors.white.withValues(alpha: 0.2), offset: const Offset(-0.5, -0.5), blurRadius: 0.5),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          // Expiry & Footer
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'VALID THRU',
                                                    style: TextStyle(color: Colors.white60, fontSize: 6, fontWeight: FontWeight.bold),
                                                  ),
                                                  const Text(
                                                    '12/28',
                                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    _savedCardLabel.trim().isEmpty || _savedCardLabel == 'No Card Linked' ? 'NSBM STUDENT' : _savedCardLabel.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Mastercard Style Logo
                                              SizedBox(
                                                width: 50,
                                                height: 32,
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEB001B).withValues(alpha: 0.9),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 18,
                                                      child: Container(
                                                        width: 32,
                                                        height: 32,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                            const SizedBox(height: 24),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext); // Close wallet sheet
                            await _startPayHereCardSetup(
                              context: context,
                              setupLabel: _savedCardLabel.trim().isEmpty
                                  ? 'Campus Card'
                                  : _savedCardLabel.trim(),
                            );
                          },
                          icon: const Icon(LucideIcons.creditCard, size: 18),
                          label: const Text('Add Credit Card'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _startPayPalLinkFlow(sheetContext);
                          },
                          icon: const Icon(LucideIcons.wallet, size: 18),
                          label: const Text('Link PayPal Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0070BA),
                            side: BorderSide(
                              color: const Color(
                                0xFF0070BA,
                              ).withValues(alpha: 0.2),
                            ),
                            backgroundColor: const Color(
                              0xFF0070BA,
                            ).withValues(alpha: 0.05),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    AppCustomColors colors,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    for (double i = -size.width; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
