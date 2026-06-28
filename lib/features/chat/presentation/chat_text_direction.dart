import 'package:flutter/widgets.dart';

final RegExp _rtlCharacterPattern = RegExp(
  r'[\u0590-\u05ff\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff\ufb50-\ufdff\ufe70-\ufeff]',
);

TextDirection textDirectionFor(String text) {
  return _rtlCharacterPattern.hasMatch(text)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

TextAlign textAlignFor(String text) {
  return textDirectionFor(text) == TextDirection.rtl
      ? TextAlign.right
      : TextAlign.left;
}
