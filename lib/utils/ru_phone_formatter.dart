// lib/utils/ru_phone_formatter.dart
import 'package:flutter/services.dart';

/// Утилиты форматирования телефонов РФ: +7 (XXX) XXX-XX-XX
class RuPhoneFormatter {
  /// Нормализация для БД: из любого ввода -> +79991234567
  static String normalize(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.startsWith('8')) d = '7${d.substring(1)}';
    if (!d.startsWith('7')) d = '7$d';
    if (d.length > 11) d = d.substring(0, 11);
    return '+$d';
  }

  /// Красивый вывод: +7 (XXX) XXX-XX-XX
  static String pretty(String input) {
    final norm = normalize(input);
    final digits = norm.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final buf = StringBuffer('+7');

    final body = digits.length > 1 ? digits.substring(1) : '';
    if (body.isEmpty) return '${buf.toString()} ';

    buf.write(' (');
    buf.write(body.substring(0, body.length.clamp(0, 3)));
    if (body.length >= 3) buf.write(') ');

    if (body.length > 3) {
      buf.write(body.substring(3, body.length.clamp(3, 6)));
      if (body.length >= 6) buf.write('-');
    }

    if (body.length > 6) {
      buf.write(body.substring(6, body.length.clamp(6, 8)));
      if (body.length >= 8) buf.write('-');
    }

    if (body.length > 8) {
      buf.write(body.substring(8, body.length.clamp(8, 10)));
    }

    return buf.toString();
  }
}

/// Текстовый форматтер ввода для TextField
class RuPhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = RuPhoneFormatter.pretty(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}