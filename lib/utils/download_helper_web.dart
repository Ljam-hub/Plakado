// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileImpl(String url, {String filename = 'Plakado.apk'}) {
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..target = '_blank'
      ..rel = 'noopener noreferrer'
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    try {
      html.window.location.href = url;
    } catch (_) {}
  }
}
