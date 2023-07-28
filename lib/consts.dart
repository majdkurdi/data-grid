import 'package:get/get.dart';

bool get arabicLocale => Get.locale?.languageCode == 'ar';

const englishLetters = [
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'o',
  'p',
  'q',
  'r',
  's',
  't',
  'u',
  'v',
  'w',
  'x',
  'y',
  'z'
];

const arabicLetters = [
  'ا',
  'ب',
  'ت',
  'ث',
  'ج',
  'ح',
  'خ',
  'د',
  'ذ',
  'ر',
  'ز',
  'س',
  'ش',
  'ص',
  'ض',
  'ط',
  'ظ',
  'ع',
  'غ',
  'ف',
  'ق',
  'ك',
  'ل',
  'م',
  'ن',
  'ه',
  'و',
  'ي',
  'أ',
];

const allSympols = [
  '&',
  '%',
  '\$',
  '.',
  '#',
  '!',
  '?',
  ':',
  '@',
  '*',
  '(',
  ')',
  '^',
  '/',
  ',',
  ' '
];
const nums = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

extension Numbers on String {
  String replaceArabicNumber() {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String res = this;
    for (int i = 0; i < english.length; i++) {
      res = res.replaceAll(arabic[i], english[i]);
    }
    return res;
  }
}
