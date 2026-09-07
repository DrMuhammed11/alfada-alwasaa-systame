import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_io.dart';

Future<void> saveAndDownloadFile(List<int> bytes, String fileName) =>
    saveAndDownloadFileImpl(bytes, fileName);

Future<void> openFileInViewer(List<int> bytes, String fileName, [String? mimeType]) =>
    openFileInViewerImpl(bytes, fileName, mimeType);
