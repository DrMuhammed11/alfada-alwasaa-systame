import 'dart:io';

Future<void> saveAndDownloadFileImpl(List<int> bytes, String fileName) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(bytes);
}

Future<void> openFileInViewerImpl(List<int> bytes, String fileName, [String? mimeType]) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(bytes);
}

Future<void> printHtmlDossierImpl(String htmlContent) async {
  // Desktop/mobile IO implementation
}
