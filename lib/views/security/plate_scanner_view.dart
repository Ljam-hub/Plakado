import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/scanner_controller.dart';
import '../widgets/yolo_bounding_box_widget.dart';
import 'verification_dialog_view.dart';

class PlateScannerView extends StatefulWidget {
  const PlateScannerView({super.key});

  @override
  State<PlateScannerView> createState() => _PlateScannerViewState();
}

class _PlateScannerViewState extends State<PlateScannerView> {
  final ImagePicker _picker = ImagePicker();
  final _manualPlateController = TextEditingController();

  @override
  void dispose() {
    _manualPlateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 90,
      );

      if (xFile != null && mounted) {
        final scanner = context.read<ScannerController>();
        await scanner.processImage(xFile.path);

        if (mounted && scanner.state == ScannerState.resultReady) {
          _showResultDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showResultDialog() {
    final scanner = context.read<ScannerController>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VerificationDialogView(
        plateNumber: scanner.recognizedPlate ?? 'UNKNOWN',
        vehicle: scanner.matchedVehicle,
        isAuthorized: scanner.isAuthorized,
        onDismiss: () => scanner.reset(),
      ),
    );
  }

  void _handleManualSearch() {
    final text = _manualPlateController.text.trim();
    if (text.isEmpty) return;
    final scanner = context.read<ScannerController>();
    scanner.verifyPlate(text);
    _manualPlateController.clear();
    _showResultDialog();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'ALPR Gate Scanner',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pipeline progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPipelineStep(1, 'YOLOv8', scanner.state == ScannerState.processingYolo),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
                  _buildPipelineStep(2, 'DIP Filter', scanner.state == ScannerState.processingDip),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
                  _buildPipelineStep(3, 'OCR Text', scanner.state == ScannerState.processingOcr),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
                  _buildPipelineStep(4, 'Verify', scanner.state == ScannerState.resultReady),
                ],
              ),
            ),

            // Camera / Viewport with YOLO Overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera backdrop or simulation background
                  Container(
                    color: const Color(0xFF0F172A),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_filled_outlined,
                            size: 110,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Align vehicle license plate inside the target box',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // YOLO Bounding Box Viewport
                  YoloBoundingBoxWidget(
                    detectedBox: scanner.detectedBox,
                    isScanning: scanner.isProcessing,
                  ),

                  // Real-time status toast
                  if (scanner.statusMessage != null)
                    Positioned(
                      top: 16,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            scanner.statusMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Control Panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Scanner Action Buttons
                  Row(
                    children: [
                      // Gallery button
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                        icon: const Icon(Icons.photo_library_outlined),
                        onPressed: scanner.isProcessing ? null : () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(width: 12),

                      // Camera Shutter Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: scanner.isProcessing ? null : () => _pickImage(ImageSource.camera),
                          icon: scanner.isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt),
                          label: Text(
                            scanner.isProcessing ? 'Processing ALPR...' : 'Capture Plate',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Manual Entry Toggle
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                        icon: const Icon(Icons.keyboard_outlined),
                        onPressed: () => _showManualEntrySheet(),
                      ),
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

  Widget _buildPipelineStep(int step, String label, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showManualEntrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manual Plate Search',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Type license plate number if the camera cannot read the plate.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualPlateController,
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Plate Number',
                  hintText: 'e.g. ABC 1234',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (_) {
                  Navigator.pop(context);
                  _handleManualSearch();
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleManualSearch();
                },
                child: const Text('Verify Plate'),
              ),
            ],
          ),
        );
      },
    );
  }
}
