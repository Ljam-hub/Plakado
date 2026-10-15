import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/vehicle_registration.dart';
import '../../models/user_profile.dart';
import '../widgets/plate_display_widget.dart';

class DigitalGatePassView extends StatelessWidget {
  final VehicleRegistration vehicle;

  const DigitalGatePassView({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    // Generate QR payload containing verification metadata
    final qrData = jsonEncode({
      'plate': vehicle.normalizedPlate,
      'owner': vehicle.ownerName,
      'role': vehicle.ownerRole.name,
      'id': vehicle.idNumber,
      'status': vehicle.status.name,
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Digital Campus Gate Pass',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // University Header Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ISUFST CAMPUS GATE PASS',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  'Valid for Academic Year 2026-2027',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // License Plate
                          PlateDisplayWidget(
                            plateNumber: vehicle.plateNumber,
                            fontSize: 24,
                          ),
                          const SizedBox(height: 20),

                          // QR Code Container
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 180,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F172A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Scan QR or ALPR Camera at Gate Checkpoint',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Owner Details
                          _buildRow('Pass Holder', vehicle.ownerName),
                          const SizedBox(height: 8),
                          _buildRow('Account Role', vehicle.ownerRole.displayName),
                          const SizedBox(height: 8),
                          _buildRow('ID Number', vehicle.idNumber),
                          const SizedBox(height: 8),
                          _buildRow('Department', vehicle.department),
                          const SizedBox(height: 8),
                          _buildRow('Vehicle', '${vehicle.make} ${vehicle.model} (${vehicle.color})'),
                          const SizedBox(height: 8),
                          _buildRow(
                            'Registration Date',
                            DateFormat('MMM dd, yyyy').format(vehicle.registeredAt),
                          ),
                        ],
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

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
