import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _data = DateFormat('dd/MM/yyyy');
final _diaMes = DateFormat('dd/MM');

String formatarMoeda(double valor) => _moeda.format(valor);

String formatarValorCompacto(double value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.toStringAsFixed(0);
}

String formatarData(DateTime data) => _data.format(data);
String formatarDiaMes(DateTime data) => _diaMes.format(data);

String chaveMes(DateTime mes) =>
    '${mes.year}-${mes.month.toString().padLeft(2, '0')}';

String nomeMes(DateTime mes) {
  const nomes = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  return '${nomes[mes.month - 1]} ${mes.year}';
}

String saudacao() {
  final hora = DateTime.now().hour;
  if (hora < 12) return 'Bom dia';
  if (hora < 18) return 'Boa tarde';
  return 'Boa noite';
}

double? parseValor(String texto) {
  var limpo = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
  limpo = limpo.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.isEmpty) return null;
  final temVirgula = limpo.contains(',');
  final temPonto = limpo.contains('.');
  if (temVirgula && temPonto) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  } else if (temVirgula) {
    limpo = limpo.replaceAll(',', '.');
  }
  return double.tryParse(limpo);
}
