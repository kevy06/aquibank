final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false);

String? validarNome(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Informe seu nome.';
  if (valor.trim().length < 2) return 'Nome muito curto.';
  return null;
}

String? validarEmail(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Informe o e-mail.';
  if (!_emailRegex.hasMatch(valor.trim())) return 'E-mail inválido.';
  return null;
}

String? validarSenha(String? valor) {
  if (valor == null || valor.isEmpty) return 'Informe a senha.';
  if (valor.length < 6) return 'Senha deve ter ao menos 6 caracteres.';
  return null;
}

String? validarTitulo(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Informe uma descrição.';
  return null;
}

String? validarValor(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Informe o valor.';
  final v = valor.trim().replaceAll('R\$', '').replaceAll(' ', '').replaceAll(',', '.');
  final n = double.tryParse(v);
  if (n == null || n <= 0) return 'Valor inválido.';
  return null;
}
