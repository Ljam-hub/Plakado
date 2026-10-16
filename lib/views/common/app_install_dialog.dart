import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/download_helper.dart';

class AppInstallDialog extends StatefulWidget {
  const AppInstallDialog({super.key});

  @override
  State<AppInstallDialog> createState() => _AppInstallDialogState();
}

class _AppInstallDialogState extends State<AppInstallDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const String webAppUrl = 'https://plakado.web.app';
  static const String apkDownloadUrl = 'https://github.com/Ljam-hub/Plakado/releases/download/v1.0.0/Plakado.apk';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _launchApkDownload() {
    DownloadHelper.downloadFile(apkDownloadUrl, filename: 'Plakado.apk');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.downloading_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Downloading Plakado.apk (97.2 MB)...'),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Copy Link',
            textColor: const Color(0xFFFDE047),
            onPressed: () => _copyUrl(apkDownloadUrl, 'APK Download URL'),
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _copyUrl(String url, String label) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard!'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/plakado_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Plakado Mobile App',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Scan QR code or download for phone/tablet',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.language, size: 18),
                      text: 'Web App (PWA)',
                    ),
                    Tab(
                      icon: Icon(Icons.android, size: 18),
                      text: 'Android APK',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Views
              SizedBox(
                height: 330,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWebTab(context, isDark),
                    _buildApkTab(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // QR Code Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: webAppUrl,
              version: QrVersions.auto,
              size: 150,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan to open plakado.web.app instantly',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // PWA Install instructions
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.install_mobile, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      'How to install without downloading 96MB:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• Android (Chrome): Tap 3-dots (⋮) → "Install App"\n• iPhone (Safari): Tap Share (↑) → "Add to Home Screen"',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _copyUrl(webAppUrl, 'Web link'),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Web App Link'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApkTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // QR Code Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: apkDownloadUrl,
              version: QrVersions.auto,
              size: 150,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF047857),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan camera to trigger direct APK download',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // Download Button
          ElevatedButton.icon(
            onPressed: _launchApkDownload,
            icon: const Icon(Icons.download, size: 20),
            label: const Text(
              'Download Plakado.apk (97.2 MB)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _copyUrl(apkDownloadUrl, 'Direct Download Link'),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Direct Download Link'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
