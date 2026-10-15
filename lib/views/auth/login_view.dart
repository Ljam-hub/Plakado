import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/user_profile.dart';
import 'otp_verification_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _deptController = TextEditingController();

  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _idNumberController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final idNumber = _idNumberController.text.trim();
    final dept = _deptController.text.trim();
    final role = _selectedRole;

    // Generate 6-digit verification code sent to their school Gmail
    auth.requestVerificationCode(email);

    // Open email verification code modal
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OtpVerificationDialog(
        email: email,
        onVerify: (code) async {
          return await auth.verifyOtpAndSignIn(
            email: email,
            code: code,
            name: name,
            role: role,
            idNumber: idNumber,
            department: dept,
          );
        },
        onResend: () {
          auth.requestVerificationCode(email);
        },
      ),
    );

    if (verified == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account verified! Signed in as ${role.displayName}.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final themeCtrl = context.watch<ThemeController>();
    final isDark = themeCtrl.isDarkMode(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 16,
              child: IconButton(
                tooltip: 'Theme: ${themeCtrl.themeModeName} (Click to switch)',
                icon: Icon(
                  themeCtrl.themeMode == ThemeMode.system
                      ? Icons.brightness_auto
                      : (isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                ),
                onPressed: () => themeCtrl.cycleTheme(),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Brand Header
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/images/plakado_logo.png',
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PLAKADO',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Campus License Plate Recognition & Gate Security',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Role Selector Segment
                        Text(
                          'SELECT USER ROLE',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildRoleTab(context, UserRole.student, 'Student'),
                              _buildRoleTab(context, UserRole.faculty, 'Faculty'),
                              _buildRoleTab(context, UserRole.security, 'Security'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Input fields
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'ISUFST School Gmail',
                            hintText: 'name@student.isufst.edu.ph or name@isufst.edu.ph',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your ISUFST email';
                            final trimmed = v.trim().toLowerCase();
                            if (!trimmed.contains('@')) return 'Enter a valid email';
                            if (!trimmed.endsWith('isufst.edu.ph')) {
                              return 'Must be an official ISUFST email (@isufst.edu.ph)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _idNumberController,
                          decoration: InputDecoration(
                            labelText: _selectedRole.idLabel,
                            hintText: 'e.g. 2023-10492-MN-0',
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Please enter ID number' : null,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _deptController,
                          decoration: InputDecoration(
                            labelText: _selectedRole == UserRole.security ? 'Gate Assignment' : 'College / Department',
                            hintText: 'e.g. College of Computer Studies',
                            prefixIcon: const Icon(Icons.account_balance_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        ElevatedButton.icon(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          icon: auth.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            auth.isLoading ? 'Authenticating...' : 'Send Code & Verify Account',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  Widget _buildRoleTab(BuildContext context, UserRole role, String label) {
    final isSelected = _selectedRole == role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
