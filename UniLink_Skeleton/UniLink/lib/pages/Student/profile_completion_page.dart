import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCampus = 'Faculty of IT';
  String? _selectedProgram;
  bool _isLoading = false;

  final Map<String, List<String>> _programsMap = {
    'Faculty of IT': [
      'BSc (Hons) in Software Engineering',
      'BSc (Hons) in Information Technology',
      'BSc (Hons) in Computer Science',
      'BSc (Hons) in Data Science',
      'BSc (Hons) in Interactive Media',
      'Other',
    ],
    'Faculty of Engineering': [
      'BSc (Hons) in Civil Engineering',
      'BSc (Hons) in Mechanical Engineering',
      'BSc (Hons) in Electrical & Electronic Engineering',
      'BSc (Hons) in Materials Engineering',
      'Other',
    ],
    'Faculty of Management': [
      'BMgt (Hons) in Human Resource Management',
      'BMgt (Hons) in Marketing Management',
      'BMgt (Hons) in Accounting & Finance',
      'BMgt (Hons) in Business Analytics',
      'Other',
    ],
    'Main Campus': [
      'Foundation in IT',
      'Foundation in Engineering',
      'Foundation in Business',
      'General English Program',
      'Other',
    ],
    'City Campus': [
      'Postgraduate Diploma in IT',
      'MBA in Business Administration',
      'Short Course in Graphic Design',
      'Other',
    ],
  };

  List<String> get _currentPrograms =>
      _programsMap[_selectedCampus] ?? ['Other'];

  @override
  void initState() {
    super.initState();
    // Default program for initial campus
    _selectedProgram = _programsMap[_selectedCampus]?.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your program')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found. Please log in again.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _nameController.text.trim(),
        'studentId': _idController.text.trim(),
        'phone': '+94${_phoneController.text.trim()}',
        'program': _selectedProgram,
        'campus': _selectedCampus,
        'email': user.email ?? 'guest@university.edu',
        'role': 'student',
        'onboarded': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withValues(alpha: 0.08),
              colors.background,
              colors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* HEADER */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _iconCircleButton(
                        icon: LucideIcons.arrowLeft,
                        onTap: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Step 1 of 1',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colors.foreground, colors.primary],
                    ).createShader(bounds),
                    child: Text(
                      'Complete Your\nProfile',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Let\'s personalize your experience at UniLink.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  /* FORM FIELDS */
                  _buildSectionHeader('PERSONAL INFORMATION', colors),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: LucideIcons.user,
                    hint: 'John Doe',
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Student / Employee ID',
                    controller: _idController,
                    icon: LucideIcons.contact,
                    hint: 'e.g. IT21004562',
                    colors: colors,
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('ACADEMIC PATHWAY', colors),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Campus / Faculty',
                    value: _selectedCampus,
                    items: _programsMap.keys.toList(),
                    icon: LucideIcons.building2,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCampus = val;
                          _selectedProgram = _programsMap[val]?.first;
                        });
                      }
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    label: 'Program / Specialization',
                    value: _selectedProgram,
                    items: _currentPrograms,
                    icon: LucideIcons.graduationCap,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProgram = val);
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Contact Number',
                    controller: _phoneController,
                    icon: LucideIcons.phone,
                    hint: '7X XXX XXXX',
                    keyboardType: TextInputType.phone,
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 8, top: 15),
                      child: Text(
                        '+94 ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    colors: colors,
                  ),

                  const SizedBox(height: 48),

                  /* SUBMIT BUTTON */
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(LucideIcons.arrowRight, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppCustomColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: colors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required AppCustomColors colors,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.foreground.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: colors.mutedForeground,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, size: 20, color: colors.primary),
              prefix: prefix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'This field is required'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    required AppCustomColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.foreground.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: colors.primary,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 20, color: colors.primary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              dropdownColor: colors.card,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, size: 20, color: colors.foreground),
      ),
    );
  }
}
