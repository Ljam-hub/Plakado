import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/gate_log_controller.dart';
import '../../models/user_profile.dart';
import '../../models/vehicle_registration.dart';
import '../../models/scan_log_model.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/plate_display_widget.dart';
import 'register_vehicle_view.dart';
import 'digital_gate_pass_view.dart';
import 'edit_profile_view.dart';
import '../common/app_install_dialog.dart';

class StudentFacultyDashboardView extends StatelessWidget {
  const StudentFacultyDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final vehicleCtrl = context.watch<VehicleController>();
    final gateCtrl = context.watch<GateLogController>();
    final themeCtrl = context.watch<ThemeController>();
    final user = auth.currentUser;
    final isDark = themeCtrl.isDarkMode(context);

    final myVehicles = user != null
        ? vehicleCtrl.getVehiclesForUser(user.email)
        : <VehicleRegistration>[];

    // User's gate scan logs
    final myLogs = gateCtrl.allLogs.where((l) {
      if (user == null) return false;
      return myVehicles.any((v) => v.normalizedPlate == l.normalizedPlate) ||
          l.driverName.toLowerCase() == user.name.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                user?.role == UserRole.student ? Icons.school : Icons.work,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Campus Pass',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    user?.role.displayName ?? 'Student',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Get Mobile App / Scan QR',
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AppInstallDialog(),
            ),
          ),
          Consumer<ThemeController>(
            builder: (context, themeCtrl, _) {
              return PopupMenuButton<ThemeMode>(
                tooltip: 'Theme: ${themeCtrl.themeModeName}',
                icon: Icon(
                  themeCtrl.themeMode == ThemeMode.system
                      ? Icons.brightness_auto
                      : (isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF2563EB),
                ),
                onSelected: (mode) => themeCtrl.setThemeMode(mode),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        const Icon(Icons.light_mode_outlined, color: Colors.amber, size: 18),
                        const SizedBox(width: 10),
                        const Text('Light Mode'),
                        if (themeCtrl.themeMode == ThemeMode.light) ...[
                          const Spacer(),
                          const Icon(Icons.check, color: Color(0xFF2563EB), size: 18),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        const Icon(Icons.dark_mode_outlined, color: Colors.indigoAccent, size: 18),
                        const SizedBox(width: 10),
                        const Text('Dark Mode'),
                        if (themeCtrl.themeMode == ThemeMode.dark) ...[
                          const Spacer(),
                          const Icon(Icons.check, color: Color(0xFF2563EB), size: 18),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        const Icon(Icons.brightness_auto, color: Colors.blueGrey, size: 18),
                        const SizedBox(width: 10),
                        const Text('System Default'),
                        if (themeCtrl.themeMode == ThemeMode.system) ...[
                          const Spacer(),
                          const Icon(Icons.check, color: Color(0xFF2563EB), size: 18),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Switch to Security Mode shortcut
          PopupMenuButton<UserRole>(
            tooltip: 'Switch Portal Mode',
            icon: const Icon(Icons.swap_horiz_rounded),
            onSelected: (role) => auth.switchRole(role),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: UserRole.security,
                child: Row(
                  children: [
                    Icon(Icons.security, size: 18),
                    SizedBox(width: 8),
                    Text('Switch to Security Guard View'),
                  ],
                ),
              ),
              if (user?.role == UserRole.student)
                const PopupMenuItem(
                  value: UserRole.faculty,
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Switch to Faculty View'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: UserRole.student,
                  child: Row(
                    children: [
                      Icon(Icons.school_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Switch to Student View'),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.inter(
                              fontSize: 22,
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
                                user?.name ?? 'Student',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user?.idNumber} • ${user?.department}',
                                style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => themeCtrl.cycleTheme(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        themeCtrl.themeMode == ThemeMode.system
                                            ? Icons.brightness_auto
                                            : (isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                                        size: 13,
                                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Theme: ${themeCtrl.themeModeName}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit Profile & Credentials',
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.all(10),
                          ),
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileView()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Registered Vehicles Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY REGISTERED VEHICLES',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterVehicleView()),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add Vehicle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (myVehicles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.no_crash_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No Vehicles Registered Yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Register your car or motorcycle plate to gain automated gate access when entering the school campus.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterVehicleView()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Register Plate Now'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myVehicles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final v = myVehicles[index];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PlateDisplayWidget(
                                    plateNumber: v.plateNumber,
                                    fontSize: 18,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${v.make} ${v.model}',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFECFDF5),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                v.status.label.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFF059669),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${v.vehicleType} • Color: ${v.color}',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Registered ${DateFormat('MMM dd, yyyy').format(v.registeredAt)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),

                              // View Gate Pass Action
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: Color(0xFF2563EB)),
                                    foregroundColor: const Color(0xFF2563EB),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DigitalGatePassView(vehicle: v),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.qr_code, size: 20),
                                  label: const Text('View Digital Gate Pass (QR & ALPR Card)'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 28),

                  // Personal Gate Activity History
                  Text(
                    'MY RECENT GATE SCANS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (myLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: const Center(
                        child: Text(
                          'No gate scans recorded yet for your vehicles.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myLogs.take(5).length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final log = myLogs[index];
                        final isEntry = log.logType == GateLogType.entry;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isEntry ? Icons.login_rounded : Icons.logout_rounded,
                                color: isEntry ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${log.plateNumber} • ${isEntry ? "Entered" : "Exited"} Campus Gate',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd • hh:mm a').format(log.timestamp),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
