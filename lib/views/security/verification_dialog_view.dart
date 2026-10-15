import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/gate_log_controller.dart';
import '../../models/vehicle_registration.dart';
import '../../models/user_profile.dart';
import '../widgets/plate_display_widget.dart';
import 'visitor_registration_view.dart';

class VerificationDialogView extends StatelessWidget {
  final String plateNumber;
  final VehicleRegistration? vehicle;
  final bool isAuthorized;
  final VoidCallback onDismiss;

  const VerificationDialogView({
    super.key,
    required this.plateNumber,
    required this.vehicle,
    required this.isAuthorized,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAuthorized
                          ? const Color(0xFFECFDF5).withValues(alpha: isDark ? 0.2 : 1.0)
                          : const Color(0xFFFFFBEB).withValues(alpha: isDark ? 0.2 : 1.0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAuthorized ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAuthorized ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: isAuthorized ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAuthorized ? 'AUTHORIZED CAMPUS VEHICLE' : 'VISITOR / UNREGISTERED',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isAuthorized
                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                                : (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context);
                      onDismiss();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // License Plate Widget
              Center(
                child: PlateDisplayWidget(
                  plateNumber: plateNumber,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 24),

              // Detail Cards
              if (isAuthorized && vehicle != null) ...[
                _buildInfoTile(
                  context,
                  icon: Icons.person,
                  label: 'Registered Driver / Owner',
                  value: vehicle!.ownerName,
                  subvalue: '${vehicle!.ownerRole.displayName} • ${vehicle!.idNumber}',
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  context,
                  icon: Icons.school,
                  label: 'College / Department',
                  value: vehicle!.department,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  context,
                  icon: Icons.directions_car,
                  label: 'Vehicle Details',
                  value: '${vehicle!.make} ${vehicle!.model}',
                  subvalue: 'Color: ${vehicle!.color} • Type: ${vehicle!.vehicleType}',
                ),
                const SizedBox(height: 24),

                // Gate Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await context.read<GateLogController>().logAuthorizedEntry(vehicle!);
                          if (context.mounted) {
                            Navigator.pop(context);
                            onDismiss();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Entry logged for ${vehicle!.plateNumber}'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Log Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF64748B)),
                        ),
                        onPressed: () async {
                          await context.read<GateLogController>().logAuthorizedExit(vehicle!);
                          if (context.mounted) {
                            Navigator.pop(context);
                            onDismiss();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exit logged for ${vehicle!.plateNumber}'),
                                backgroundColor: const Color(0xFF2563EB),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log Exit', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Unregistered / Visitor View
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB).withValues(alpha: isDark ? 0.15 : 1.0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No registration record found for plate $plateNumber.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This vehicle must be issued a Visitor Gate Pass to proceed inside campus grounds.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VisitorRegistrationView(initialPlate: plateNumber),
                      ),
                    );
                  },
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Register Visitor Pass', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subvalue,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (subvalue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subvalue,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
