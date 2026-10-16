import 'package:url_launcher/url_launcher.dart';

void downloadFileImpl(String url, {String filename = 'Plakado.apk'}) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
