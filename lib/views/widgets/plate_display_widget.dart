import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlateDisplayWidget extends StatelessWidget {
  final String plateNumber;
  final double fontSize;
  final bool isMotorcycle;
  final String? regionOrSubtext;

  const PlateDisplayWidget({
    super.key,
    required this.plateNumber,
    this.fontSize = 24,
    this.isMotorcycle = false,
    this.regionOrSubtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top plate header strip (e.g. PILIPINAS / NCR)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                regionOrSubtext ?? 'PILIPINAS',
                style: GoogleFonts.robotoMono(
                  fontSize: fontSize * 0.35,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Main License Plate Characters
          Text(
            plateNumber.toUpperCase(),
            style: GoogleFonts.robotoMono(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
