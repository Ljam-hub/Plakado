import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/gate_log_controller.dart';
import '../../utils/plate_formatter.dart';
import '../widgets/plate_display_widget.dart';

class VisitorRegistrationView extends StatefulWidget {
  final String? initialPlate;

  const VisitorRegistrationView({super.key, this.initialPlate});

  @override
  State<VisitorRegistrationView> createState() => _VisitorRegistrationViewState();
}

class _VisitorRegistrationViewState extends State<VisitorRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plateController;
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passNumberController = TextEditingController();

  String _selectedPurpose = 'Official School Business';
  String _selectedBuilding = 'Administration Building';
  String _selectedId = "Driver's License";

  final List<String> _purposes = [
    'Official School Business',
    'Registrar / Enrollment',
    'Parent / Guardian Inquiry',
    'Package / Food Delivery',
    'Campus Event / Seminar',
    'Maintenance / Contractor',
    'Guest / Meeting',
  ];

  final List<String> _buildings = [
    'Administration Building',
    'College of Fisheries & Ocean Sciences',
    'College of Information & Computing Studies',
    'ISUFST Library & Learning Commons',
    'Gymnasium & Sports Complex',
    'Student Center',
    'ISUFST Health Clinic',
  ];

  final List<String> _idTypes = [
    "Driver's License",
    "National ID (PhilSys)",
    "UMID / SSS",
    "Company ID",
    "Passport",
    "Voter's ID",
  ];

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(text: widget.initialPlate ?? '');
    _passNumberController.text = 'VP-${100 + Random().nextInt(899)}';
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _passNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitVisitor() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<GateLogController>();
    await controller.registerVisitorEntry(
      plateNumber: _plateController.text,
      visitorName: _nameController.text,
      contactNumber: _contactController.text,
      purpose: _selectedPurpose,
      destinationBuilding: _selectedBuilding,
      passNumber: _passNumberController.text,
      idPresented: _selectedId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visitor Pass ${_passNumberController.text} issued to ${_nameController.text}!'),
        backgroundColor: const Color(0xFFF59E0B),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Visitor Vehicle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Plate preview
                    if (_plateController.text.isNotEmpty) ...[
                      Center(
                        child: PlateDisplayWidget(
                          plateNumber: _plateController.text,
                          regionOrSubtext: 'VISITOR VEHICLE',
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    TextFormField(
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Plate Number',
                        hintText: 'e.g. ABC 1234',
                        prefixIcon: Icon(Icons.pin),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter plate number';
                        if (!PlateFormatter.isValidPlate(v)) return 'Enter valid plate format';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Visitor Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter visitor name' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        hintText: '09XX XXX XXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter contact number' : null,
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedPurpose,
                      decoration: const InputDecoration(
                        labelText: 'Purpose of Visit',
                        prefixIcon: Icon(Icons.assignment_outlined),
                      ),
                      items: _purposes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setState(() => _selectedPurpose = v!),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedBuilding,
                      decoration: const InputDecoration(
                        labelText: 'Destination Building / Office',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      items: _buildings.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() => _selectedBuilding = v!),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedId,
                            decoration: const InputDecoration(
                              labelText: 'ID Presented',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: _idTypes.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                            onChanged: (v) => setState(() => _selectedId = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _passNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Pass #',
                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter pass #' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitVisitor,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'Issue Visitor Pass & Log Entry',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
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
