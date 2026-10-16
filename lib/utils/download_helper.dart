import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

abstract class DownloadHelper {
  static void downloadFile(String url, {String filename = 'Plakado.apk'}) {
    downloadFileImpl(url, filename: filename);
  }
}
