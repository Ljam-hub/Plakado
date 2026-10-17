import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_profile.dart';
import '../common/app_install_dialog.dart';
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
  UserRole? _lockedRole;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim().toLowerCase();
    final auth = context.read<AuthController>();
    final account = auth.getAccountByEmail(email);

    if (account != null) {
      if (_selectedRole != account.role || _lockedRole != account.role) {
        setState(() {
          _selectedRole = account.role;
          _lockedRole = account.role;
          if (_nameController.text.isEmpty && account.name.isNotEmpty) {
            _nameController.text = account.name;
          }
          if (_idNumberController.text.isEmpty && account.idNumber.isNotEmpty) {
            _idNumberController.text = account.idNumber;
          }
          if (_deptController.text.isEmpty && account.department.isNotEmpty) {
            _deptController.text = account.department;
          }
        });
      }
    } else {
      if (email.startsWith('student') || email.contains('.student') || email.contains('student.')) {
        if (_selectedRole != UserRole.student || _lockedRole != UserRole.student) {
          setState(() {
            _selectedRole = UserRole.student;
            _lockedRole = UserRole.student;
          });
        }
      } else if (email.startsWith('security') || email.contains('guard') || email.contains('security.')) {
        if (_selectedRole != UserRole.security || _lockedRole != UserRole.security) {
          setState(() {
            _selectedRole = UserRole.security;
            _lockedRole = UserRole.security;
          });
        }
      } else if (email.startsWith('faculty') || email.startsWith('prof') || email.contains('faculty.')) {
        if (_selectedRole != UserRole.faculty || _lockedRole != UserRole.faculty) {
          setState(() {
            _selectedRole = UserRole.faculty;
            _lockedRole = UserRole.faculty;
          });
        }
      } else {
        if (_lockedRole != null) {
          setState(() {
            _lockedRole = null;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
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

  Future<void> _quickLogin({
    required String email,
    required String name,
    required UserRole role,
    required String idNumber,
    required String department,
  }) async {
    final auth = context.read<AuthController>();
    final success = await auth.signInWithSchoolGoogle(
      email: email,
      name: name,
      role: role,
      idNumber: idNumber,
      department: department,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed in as ${role.displayName} ($name)'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (kIsWeb) ...[
            TextButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AppInstallDialog(),
              ),
              icon: const Icon(Icons.install_mobile, size: 18),
              label: const Text(
                'Install App / QR',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SafeArea(
        child: Center(
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
                        Row(
                          children: [
                            Text(
                              'SELECT USER ROLE',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                            if (_lockedRole != null) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock, size: 11, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Account Locked (${_lockedRole!.displayName})',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                            hintText: 'e.g. College of Informatics and Computing Innovations',
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
                        const SizedBox(height: 20),

                        // Quick Test Accounts (1-Tap Login)
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'QUICK TEST ACCOUNTS (1-TAP)',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _quickLogin(
                                          email: 'student@isufst.edu.ph',
                                          name: 'Student Test User',
                                          role: UserRole.student,
                                          idNumber: '2024-00101',
                                          department: 'College of Informatics and Computing Innovations',
                                        ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🎓 Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text('student@...', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _quickLogin(
                                          email: 'faculty@isufst.edu.ph',
                                          name: 'Prof. Faculty User',
                                          role: UserRole.faculty,
                                          idNumber: 'FAC-2024-001',
                                          department: 'College of Industrial Technology',
                                        ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('👔 Faculty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text('faculty@...', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _quickLogin(
                                          email: 'security@isufst.edu.ph',
                                          name: 'Officer Security Guard',
                                          role: UserRole.security,
                                          idNumber: 'SEC-2024-001',
                                          department: 'Campus Security Office',
                                        ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🛡️ Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text('security@...', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (kIsWeb) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'MOBILE ACCESS',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const AppInstallDialog(),
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB)),
                            label: const Text('Install App / Scan QR Code'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(BuildContext context, UserRole role, String label) {
    final isSelected = _selectedRole == role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLockedOut = _lockedRole != null && _lockedRole != role;

    return Expanded(
      child: GestureDetector(
        onTap: isLockedOut
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account permanently bound to ${_lockedRole!.displayName}. Role cannot be switched.'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                );
              }
            : () => setState(() => _selectedRole = role),
        child: Opacity(
          opacity: isLockedOut ? 0.4 : 1.0,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected && _lockedRole == role) ...[
                  const Icon(Icons.lock, size: 11, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                ],
                Text(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
