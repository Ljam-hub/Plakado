import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/vehicle_controller.dart';
import '../../models/user_profile.dart';
import '../widgets/plate_display_widget.dart';

class RegisteredVehiclesDirectory extends StatefulWidget {
  const RegisteredVehiclesDirectory({super.key});

  @override
  State<RegisteredVehiclesDirectory> createState() => _RegisteredVehiclesDirectoryState();
}

class _RegisteredVehiclesDirectoryState extends State<RegisteredVehiclesDirectory> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final vehicleController = context.watch<VehicleController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final vehicles = vehicleController.vehicles.where((v) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return v.plateNumber.toLowerCase().contains(q) ||
          v.ownerName.toLowerCase().contains(q) ||
          v.idNumber.toLowerCase().contains(q) ||
          v.department.toLowerCase().contains(q) ||
          v.make.toLowerCase().contains(q) ||
          v.model.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Campus Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vehicleController.loadVehicles(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search plate, owner name, ID, or department...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: vehicles.isEmpty
                ? Center(
                    child: Text(
                      'No registered vehicles found',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: vehicles.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlateDisplayWidget(
                              plateNumber: v.plateNumber,
                              fontSize: 14,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          v.ownerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5).withValues(alpha: isDark ? 0.2 : 1.0),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          v.ownerRole.displayName.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${v.idNumber} • ${v.department}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${v.vehicleType}: ${v.make} ${v.model} (${v.color})',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
