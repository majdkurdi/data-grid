import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

Future<String?> readFromClipboard() async {
  try {
    if (kIsWeb) {
      return await html.window.navigator.clipboard?.readText();
    } else {
      return (await Clipboard.getData('text/plain'))?.text;
    }
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
  final rows =
      clipboardText.split('\n').map((e) => e.replaceAll('\u{000D}', '')).toList();
  final List<List<String>> parsedData = rows
      .map((row) => row.split('\t').map((e) => e.replaceAll('\t', '')).toList())
      .toList();
  return parsedData;
}

Future<dynamic> dataFromClipboard() async {
  final text = await readFromClipboard();
  print('paste');
  print(text);
  if (text == null) return null;
  if (text.contains('\n') || text.contains('\t')) return parseExcelClipboard();
  return text;
}

void copyToClipboard(String text) {
  html.window.navigator.clipboard?.writeText(text);
}
