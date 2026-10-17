import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../models/user_profile.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _idNumberController;
  late TextEditingController _deptController;
  late TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _idNumberController = TextEditingController(text: user?.idNumber ?? '');
    _deptController = TextEditingController(text: user?.department ?? '');
    _contactController = TextEditingController(text: user?.contactNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _deptController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final vehicleCtrl = context.read<VehicleController>();

    final success = await auth.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      idNumber: _idNumberController.text,
      department: _deptController.text,
      contactNumber: _contactController.text,
    );

    if (!mounted) return;

    if (success) {
      vehicleCtrl.loadVehicles(); // Refresh vehicle owner bindings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credentials and profile updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Credentials & Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            child: Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.role.displayName.toUpperCase() ?? 'USER',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.name ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).textTheme.titleMedium?.color,
                                  ),
                                ),
                                Text(
                                  'Linked to campus vehicle records',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter full name' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'ISUFST School Gmail',
                        prefixIcon: Icon(Icons.alternate_email),
                        helperText: 'Official ISUFST email domain (@isufst.edu.ph)',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter school email';
                        final trimmed = v.trim().toLowerCase();
                        if (!trimmed.contains('@')) return 'Enter valid email address';
                        if (!trimmed.endsWith('isufst.edu.ph')) {
                          return 'Must be an official ISUFST email (@isufst.edu.ph)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _idNumberController,
                      decoration: InputDecoration(
                        labelText: user?.role.idLabel ?? 'ID Number',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter ID number' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _deptController,
                      decoration: InputDecoration(
                        labelText: user?.role == UserRole.security ? 'Gate Assignment' : 'College / Department',
                        hintText: 'e.g. College of Informatics and Computing Innovations',
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter department' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact / Mobile Number',
                        hintText: '09XX XXX XXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: auth.isLoading ? null : _handleSave,
                      icon: auth.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          auth.isLoading ? 'Saving Changes...' : 'Save Updated Credentials',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
