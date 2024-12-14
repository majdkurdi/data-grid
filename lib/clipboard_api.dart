import 'package:universal_html/html.dart' as html;

Future<String?> readFromClipboard() async {
  try {
    return await html.window.navigator.clipboard?.readText();
  } catch (e) {
    print('Failed to read clipboard: $e');
    return null;
  }
}

Future<List<List<String>>> parseExcelClipboard() async {
  final clipboardText = await readFromClipboard();
  if (clipboardText == null || clipboardText.isEmpty) {
    return [];
  }
  final rows = clipboardText.split('\n');
  final List<List<String>> parsedData = rows.map((row) => row.split('\t')).toList();
  return parsedData;
}

Future<dynamic> dataFromClipboard() async {
  final text = await readFromClipboard();
  print('paste');
  print(text);
  if(text == null) return null;
  if(text.contains('\n') || text.contains('\t')) return parseExcelClipboard();
  return text;
}

void copyToClipboard(String text) {
  html.window.navigator.clipboard?.writeText(text);
}