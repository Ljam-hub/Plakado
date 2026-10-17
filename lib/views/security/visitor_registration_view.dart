import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/gate_log_controller.dart';
import '../../controllers/scanner_controller.dart';
import '../../utils/plate_formatter.dart';
import '../widgets/plate_display_widget.dart';
import 'plate_scanner_view.dart';

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
  final _customPurposeController = TextEditingController();
  final _customDestinationController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  bool _isScanningPlate = false;
  bool _isSubmitting = false;

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
    'Others (Please specify)',
  ];

  final List<String> _buildings = [
    'Administration Building',
    'College of Industrial Technology',
    'College of Business, Management, and Sustainable Development',
    'College of Informatics and Computing Innovations',
    'ISUFST Library & Learning Commons',
    'Gymnasium & Sports Complex',
    'Student Center',
    'ISUFST Health Clinic',
    'Others (Please specify)',
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
    _customPurposeController.dispose();
    _customDestinationController.dispose();
    super.dispose();
  }

  Future<void> _scanPlate(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 90,
      );

      if (xFile == null || !mounted) return;

      setState(() => _isScanningPlate = true);

      final scanner = context.read<ScannerController>();
      final recognized = await scanner.recognizePlateOnly(xFile.path);

      if (!mounted) return;
      setState(() => _isScanningPlate = false);

      if (recognized != null && recognized.isNotEmpty) {
        setState(() {
          _plateController.text = recognized;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Plate Auto-Detected: $recognized')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not clearly detect plate. Point directly at plate or enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanningPlate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showScanPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.document_scanner, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Scan Visitor License Plate',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Use camera OCR to scan the vehicle plate and automatically fill the plate number field.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
                ),
                title: Text('Take Photo with Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Capture live physical plate on visitor vehicle', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanPlate(ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF3B82F6)),
                ),
                title: Text('Upload from Gallery / Files', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Select a saved plate photo from your device', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanPlate(ImageSource.gallery);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.center_focus_strong, color: Color(0xFFF59E0B)),
                ),
                title: Text('Open Full ALPR Scanner', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Live viewfinder with YOLO bounding box detector', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(ctx);
                  final scannedPlate = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlateScannerView(returnPlateOnly: true),
                    ),
                  );
                  if (scannedPlate != null && scannedPlate.isNotEmpty && mounted) {
                    setState(() {
                      _plateController.text = scannedPlate;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Plate Scanner Result: $scannedPlate'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitVisitor() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final controller = context.read<GateLogController>();
      final finalPurpose = _selectedPurpose == 'Others (Please specify)'
          ? (_customPurposeController.text.trim().isNotEmpty
              ? _customPurposeController.text.trim()
              : 'Other Purpose')
          : _selectedPurpose;
      final finalDestination = _selectedBuilding == 'Others (Please specify)'
          ? (_customDestinationController.text.trim().isNotEmpty
              ? _customDestinationController.text.trim()
              : 'Other Destination')
          : _selectedBuilding;

      await controller.registerVisitorEntry(
        plateNumber: _plateController.text,
        visitorName: _nameController.text,
        contactNumber: _contactController.text,
        purpose: finalPurpose,
        destinationBuilding: finalDestination,
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                      decoration: InputDecoration(
                        labelText: 'Plate Number',
                        hintText: 'e.g. ABC 1234',
                        prefixIcon: const Icon(Icons.pin),
                        suffixIcon: _isScanningPlate
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Scan License Plate with Camera',
                                icon: const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
                                onPressed: _showScanPicker,
                              ),
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
                      isExpanded: true,
                      initialValue: _selectedPurpose,
                      decoration: const InputDecoration(
                        labelText: 'Purpose of Visit',
                        prefixIcon: Icon(Icons.assignment_outlined),
                      ),
                      selectedItemBuilder: (context) => _purposes
                          .map((p) => Text(
                                p,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ))
                          .toList(),
                      items: _purposes
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPurpose = v!),
                    ),
                    if (_selectedPurpose == 'Others (Please specify)') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customPurposeController,
                        decoration: const InputDecoration(
                          labelText: 'Specify Purpose of Visit',
                          hintText: 'e.g. Alumni Transaction, Vendor Pitch',
                          prefixIcon: Icon(Icons.edit_note_outlined),
                        ),
                        validator: (v) {
                          if (_selectedPurpose == 'Others (Please specify)' && (v == null || v.trim().isEmpty)) {
                            return 'Please specify purpose of visit';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedBuilding,
                      decoration: const InputDecoration(
                        labelText: 'Destination Building / Office',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      selectedItemBuilder: (context) => _buildings
                          .map((b) => Text(
                                b,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ))
                          .toList(),
                      items: _buildings
                          .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBuilding = v!),
                    ),
                    if (_selectedBuilding == 'Others (Please specify)') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customDestinationController,
                        decoration: const InputDecoration(
                          labelText: 'Specify Destination / Office',
                          hintText: 'e.g. Faculty Lounge, Guard House, Field',
                          prefixIcon: Icon(Icons.add_location_alt_outlined),
                        ),
                        validator: (v) {
                          if (_selectedBuilding == 'Others (Please specify)' && (v == null || v.trim().isEmpty)) {
                            return 'Please specify destination building or office';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 420;
                        if (isNarrow) {
                          return Column(
                            children: [
                              _buildIdDropdown(),
                              const SizedBox(height: 14),
                              _buildPassField(),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildIdDropdown()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildPassField()),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isSubmitting ? null : _submitVisitor,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isSubmitting ? 'Issuing Visitor Pass...' : 'Issue Visitor Pass & Log Entry',
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

  Widget _buildIdDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedId,
      decoration: const InputDecoration(
        labelText: 'ID Presented',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      items: _idTypes
          .map((i) => DropdownMenuItem(
                value: i,
                child: Text(i, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedId = v!),
    );
  }

  Widget _buildPassField() {
    return TextFormField(
      controller: _passNumberController,
      decoration: const InputDecoration(
        labelText: 'Assigned Pass #',
        prefixIcon: Icon(Icons.confirmation_number_outlined),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Enter pass #' : null,
    );
  }
}
