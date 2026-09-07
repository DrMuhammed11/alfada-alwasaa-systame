// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> saveAndDownloadFileImpl(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

Future<void> openFileInViewerImpl(List<int> bytes, String fileName, [String? mimeType]) async {
  final mime = mimeType ?? (fileName.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream');
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Revoke object URL after delay so browser has time to load it in the new tab
  Future.delayed(const Duration(minutes: 5), () => html.Url.revokeObjectUrl(url));
}

Future<void> printHtmlDossierImpl(String htmlContent) async {
  final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future.delayed(const Duration(minutes: 5), () => html.Url.revokeObjectUrl(url));
}
