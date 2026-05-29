import 'package:flutter_test/flutter_test.dart';
import 'package:aquibank/core/utils/validators.dart';

void main() {
  group('validadores', () {
    test('valida e-mail obrigatório e formato', () {
      expect(validarEmail(null), isNotNull);
      expect(validarEmail('email-invalido'), isNotNull);
      expect(validarEmail('usuario@email.com'), isNull);
    });

    test('valida senha mínima', () {
      expect(validarSenha(''), isNotNull);
      expect(validarSenha('123'), isNotNull);
      expect(validarSenha('123456'), isNull);
    });

    test('valida valor positivo', () {
      expect(validarValor(''), isNotNull);
      expect(validarValor('0'), isNotNull);
      expect(validarValor('12,50'), isNull);
    });
  });
}
