import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    final cents = int.parse(digits);
    final reais = cents ~/ 100;
    final centavos = cents % 100;

    final reaisFormatted = _formatarMilhares(reais);
    final texto = 'R\$ $reaisFormatted,${centavos.toString().padLeft(2, '0')}';

    return newValue.copyWith(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  String _formatarMilhares(int valor) {
    final s = valor.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

double parseCurrency(String texto) {
  final digits = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.parse(digits) / 100;
}
