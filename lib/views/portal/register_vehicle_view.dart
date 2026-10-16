import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/scanner_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../models/user_profile.dart';
import '../../utils/plate_formatter.dart';
import '../widgets/plate_display_widget.dart';

class RegisterVehicleView extends StatefulWidget {
  const RegisterVehicleView({super.key});

  @override
  State<RegisterVehicleView> createState() => _RegisterVehicleViewState();
}

class _RegisterVehicleViewState extends State<RegisterVehicleView> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();

  String _selectedVehicleType = 'Car (Sedan)';

  final List<String> _vehicleTypes = [
    'Car (Sedan)',
    'Hatchback',
    'SUV / Crossover',
    'Motorcycle (Manual/Scooter)',
    'Van / MPV',
    'Pickup Truck',
    'E-Bike / Electric',
  ];

  final List<String> _popularColors = [
    'Pearl White',
    'Glossy Black',
    'Silver Metallic',
    'Titanium Gray',
    'Deep Blue',
    'Ruby Red',
  ];

  final ImagePicker _picker = ImagePicker();
  bool _isScanningPlate = false;

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
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
                Text('Plate Auto-Detected: $recognized'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not clearly detect plate. Please enter manually or try another angle.'),
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                  'Scan License Plate',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Use AI camera scanning or select an image of your vehicle plate to automatically fill this field.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
              ),
              title: Text('Take Photo with Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: const Text('Capture live physical plate on your vehicle', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _scanPlate(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF3B82F6)),
              ),
              title: Text('Upload from Gallery / Files', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: const Text('Select a saved plate photo from your device', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _scanPlate(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final vehicleCtrl = context.read<VehicleController>();
    final user = auth.currentUser;

    if (user == null) return;

    final success = await vehicleCtrl.registerNewVehicle(
      plateNumber: _plateController.text,
      owner: user,
      vehicleType: _selectedVehicleType,
      make: _makeController.text,
      model: _modelController.text,
      color: _colorController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle ${_plateController.text.toUpperCase()} successfully registered!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } else if (vehicleCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vehicleCtrl.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final vehicleCtrl = context.watch<VehicleController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Plate & Vehicle'),
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
                    // Info Banner
                    Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : const Color(0xFFDBEAFE),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Registering as ${user?.role.displayName}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    Text(
                                      'Linked to ${user?.email} (${user?.idNumber})',
                                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // AI Plate Auto-Scan Action Card
                    Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return InkWell(
                          onTap: _isScanningPlate ? null : _showScanPicker,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.4 : 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isScanningPlate
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.document_scanner, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _isScanningPlate ? 'Analyzing plate...' : 'Scan Plate with Camera',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'AI OCR',
                                              style: TextStyle(
                                                color: Color(0xFF10B981),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Snap physical plate or pick image to auto-fill',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.camera_alt,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // License Plate Preview
                    if (_plateController.text.isNotEmpty) ...[
                      Center(
                        child: PlateDisplayWidget(
                          plateNumber: _plateController.text,
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
                        hintText: 'e.g. ABC 1234 or 123 ABC',
                        prefixIcon: Icon(Icons.pin),
                        helperText: 'Standard Philippine 4-wheel or motorcycle plate',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter plate number';
                        if (!PlateFormatter.isValidPlate(v)) {
                          return 'Invalid format (Must have letters and numbers, e.g. ABC 1234)';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _selectedVehicleType = v!),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _makeController,
                            decoration: const InputDecoration(
                              labelText: 'Brand / Make',
                              hintText: 'e.g. Toyota, Honda',
                              prefixIcon: Icon(Icons.car_repair),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter vehicle make' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              hintText: 'e.g. Vios, Click 125',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter vehicle model' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Color',
                        hintText: 'e.g. Pearl White, Matte Black',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter vehicle color' : null,
                    ),
                    const SizedBox(height: 8),

                    // Quick color suggestion chips
                    Wrap(
                      spacing: 8,
                      children: _popularColors.map((color) {
                        return ActionChip(
                          label: Text(color, style: const TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _colorController.text = color),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: vehicleCtrl.isLoading ? null : _handleRegister,
                      icon: vehicleCtrl.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.app_registration),
                      label: Text(
                        vehicleCtrl.isLoading ? 'Registering...' : 'Register Vehicle & Generate Gate Pass',
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
