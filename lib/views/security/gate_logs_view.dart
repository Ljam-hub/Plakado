import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/gate_log_controller.dart';
import '../../models/scan_log_model.dart';

class GateLogsView extends StatelessWidget {
  const GateLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GateLogController>();
    final logs = controller.filteredLogs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Gate Activity Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: Column(
              children: [
                TextField(
                  onChanged: (q) => controller.setSearchQuery(q),
                  decoration: InputDecoration(
                    hintText: 'Search plate, driver name, or department...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: controller.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => controller.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(context, 'ALL', 'All Activity (${controller.allLogs.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'STUDENT', 'Students'),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'FACULTY', 'Faculty / Staff'),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'VISITOR', 'Visitors / Guests'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Logs List
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No gate logs matching your search',
                          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isAuthorized = log.accessStatus == AccessStatus.authorized;
                      final isEntry = log.logType == GateLogType.entry;

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
                            // Entry / Exit indicator icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isEntry
                                    ? const Color(0xFFECFDF5).withValues(alpha: isDark ? 0.2 : 1.0)
                                    : const Color(0xFFEFF6FF).withValues(alpha: isDark ? 0.2 : 1.0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEntry ? Icons.login_rounded : Icons.logout_rounded,
                                color: isEntry ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Main Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.plateNumber,
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isAuthorized
                                              ? const Color(0xFFECFDF5).withValues(alpha: isDark ? 0.2 : 1.0)
                                              : const Color(0xFFFFFBEB).withValues(alpha: isDark ? 0.2 : 1.0),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isAuthorized
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF59E0B),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isAuthorized ? 'AUTHORIZED' : 'VISITOR',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isAuthorized
                                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                                                : (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.driverName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (log.department != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      log.department!,
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                  if (log.vehicleInfo != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      log.vehicleInfo!,
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy • hh:mm a').format(log.timestamp),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
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

  Widget _buildFilterChip(BuildContext context, String filterKey, String label) {
    final controller = context.watch<GateLogController>();
    final isSelected = controller.selectedRoleFilter == filterKey;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setRoleFilter(filterKey),
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
