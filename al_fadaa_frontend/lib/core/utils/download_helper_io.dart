import 'dart:io';

Future<void> saveAndDownloadFileImpl(List<int> bytes, String fileName) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(bytes);
}
