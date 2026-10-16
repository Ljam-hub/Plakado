import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/gate_log_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/scan_log_model.dart';
import '../../models/user_profile.dart';
import '../widgets/quick_stat_card.dart';
import 'plate_scanner_view.dart';
import 'visitor_registration_view.dart';
import 'gate_logs_view.dart';
import 'registered_vehicles_directory.dart';
import '../portal/edit_profile_view.dart';
import '../common/app_install_dialog.dart';

class SecurityDashboardView extends StatelessWidget {
  const SecurityDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final gateController = context.watch<GateLogController>();
    final user = auth.currentUser;
    final recentLogs = gateController.allLogs.take(5).toList();

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
              child: const Icon(Icons.security, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gate Security',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${user?.name ?? "Officer"} (${user?.idNumber ?? "Main Gate"})',
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
              final isDark = themeCtrl.isDarkMode(context);
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
          IconButton(
            tooltip: 'Edit Officer Credentials',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileView()),
              );
            },
          ),
          // Switch Role Menu
          PopupMenuButton<UserRole>(
            tooltip: 'Switch Portal Mode',
            icon: const Icon(Icons.swap_horiz_rounded),
            onSelected: (role) => auth.switchRole(role),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: UserRole.student,
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Switch to Student Portal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: UserRole.faculty,
                child: Row(
                  children: [
                    Icon(Icons.work_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Switch to Faculty Portal'),
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
        child: RefreshIndicator(
          onRefresh: () async => gateController.refreshLogs(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Scanner Launcher Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF10B981), width: 1),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt, color: Color(0xFF10B981), size: 12),
                                    SizedBox(width: 6),
                                    Text(
                                      'YOLOv8 + DIP OCR ACTIVE',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Automatic License Plate Scanner',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan incoming vehicles at the gate. Instantly verifies registration, flags visitors, and records entry/exit logs.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PlateScannerView()),
                              );
                            },
                            icon: const Icon(Icons.center_focus_strong, size: 22),
                            label: Text(
                              'OPEN GATE CAMERA SCANNER',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            icon: Icons.person_add_alt_1,
                            label: 'Register Visitor',
                            accent: const Color(0xFFF59E0B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const VisitorRegistrationView()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            icon: Icons.directions_car_filled,
                            label: 'Vehicle Directory',
                            accent: const Color(0xFF2563EB),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisteredVehiclesDirectory()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Live Campus Metrics Grid
                    Text(
                      'CAMPUS GATE STATS (TODAY)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 600;
                        return GridView.count(
                          crossAxisCount: isDesktop ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isDesktop ? 1.4 : 1.3,
                          children: [
                            QuickStatCard(
                              title: 'Total Scans',
                              value: '${gateController.allLogs.length}',
                              icon: Icons.qr_code_scanner,
                              accentColor: const Color(0xFF2563EB),
                              subtitle: 'Main & Side Gates',
                            ),
                            QuickStatCard(
                              title: 'Students',
                              value: '${gateController.studentCountToday}',
                              icon: Icons.school,
                              accentColor: const Color(0xFF10B981),
                              subtitle: 'Active Vehicles',
                            ),
                            QuickStatCard(
                              title: 'Faculty / Staff',
                              value: '${gateController.facultyCountToday}',
                              icon: Icons.work,
                              accentColor: const Color(0xFF6366F1),
                              subtitle: 'Authorized Passes',
                            ),
                            QuickStatCard(
                              title: 'Active Visitors',
                              value: '${gateController.visitorCountToday}',
                              icon: Icons.badge_outlined,
                              accentColor: const Color(0xFFF59E0B),
                              subtitle: 'Passes Issued',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Recent Gate Feed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT GATE ACTIVITY',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GateLogsView()),
                            );
                          },
                          child: const Text('View All Logs'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (recentLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: const Center(
                          child: Text('No gate logs recorded yet.'),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentLogs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = recentLogs[index];
                          final isAuthorized = log.accessStatus == AccessStatus.authorized;
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${log.plateNumber} • ${log.driverName}',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${log.department ?? "Visitor"} • ${DateFormat('hh:mm a').format(log.timestamp)}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAuthorized ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAuthorized ? 'ALLOWED' : 'VISITOR',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAuthorized ? const Color(0xFF059669) : const Color(0xFFD97706),
                                    ),
                                  ),
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
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
