import 'dart:convert';
import 'package:http/http.dart' as http;

class Cotacao {
  final String codigo;
  final String nome;
  final double bid;
  final double pctChange;
  final double high;
  final double low;

  const Cotacao({
    required this.codigo,
    required this.nome,
    required this.bid,
    required this.pctChange,
    required this.high,
    required this.low,
  });

  bool get isPositive => pctChange >= 0;

  factory Cotacao.fromJson(String nome, Map<String, dynamic> json) {
    return Cotacao(
      codigo: json['code'] ?? '',
      nome: nome,
      bid: double.tryParse(json['bid']?.toString() ?? '0') ?? 0,
      pctChange: double.tryParse(json['pctChange']?.toString() ?? '0') ?? 0,
      high: double.tryParse(json['high']?.toString() ?? '0') ?? 0,
      low: double.tryParse(json['low']?.toString() ?? '0') ?? 0,
    );
  }
}

class CotacaoService {
  static const _base = 'https://economia.awesomeapi.com.br/json/last';

  static const _moedas = [
    ('USD-BRL', 'Dólar Americano', '🇺🇸'),
    ('EUR-BRL', 'Euro', '🇪🇺'),
    ('GBP-BRL', 'Libra Esterlina', '🇬🇧'),
    ('JPY-BRL', 'Iene Japonês', '🇯🇵'),
    ('CHF-BRL', 'Franco Suíço', '🇨🇭'),
    ('CAD-BRL', 'Dólar Canadense', '🇨🇦'),
    ('AUD-BRL', 'Dólar Australiano', '🇦🇺'),
    ('CNY-BRL', 'Yuan Chinês', '🇨🇳'),
    ('ARS-BRL', 'Peso Argentino', '🇦🇷'),
    ('BTC-BRL', 'Bitcoin', '₿'),
    ('ETH-BRL', 'Ethereum', 'Ξ'),
  ];

  Future<List<({Cotacao cotacao, String emoji})>> buscarCotacoes() async {
    try {
      final pares = _moedas.map((m) => m.$1).join(',');
      final uri = Uri.parse('$_base/$pares');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _cotacoesMock();

      final data = json.decode(response.body) as Map<String, dynamic>;
      final resultado = <({Cotacao cotacao, String emoji})>[];

      for (final m in _moedas) {
        final key = m.$1.replaceAll('-', '');
        if (data.containsKey(key)) {
          resultado.add((
            cotacao: Cotacao.fromJson(m.$2, data[key] as Map<String, dynamic>),
            emoji: m.$3,
          ));
        }
      }

      return resultado.isEmpty ? _cotacoesMock() : resultado;
    } catch (_) {
      return _cotacoesMock();
    }
  }

  List<({Cotacao cotacao, String emoji})> _cotacoesMock() => [
    (cotacao: const Cotacao(codigo: 'USD', nome: 'Dólar Americano', bid: 5.18, pctChange: 0.42, high: 5.22, low: 5.14), emoji: '🇺🇸'),
    (cotacao: const Cotacao(codigo: 'EUR', nome: 'Euro', bid: 5.65, pctChange: 0.18, high: 5.70, low: 5.60), emoji: '🇪🇺'),
    (cotacao: const Cotacao(codigo: 'GBP', nome: 'Libra Esterlina', bid: 6.62, pctChange: -0.11, high: 6.68, low: 6.58), emoji: '🇬🇧'),
    (cotacao: const Cotacao(codigo: 'JPY', nome: 'Iene Japonês', bid: 0.0342, pctChange: -0.23, high: 0.0348, low: 0.0338), emoji: '🇯🇵'),
    (cotacao: const Cotacao(codigo: 'CHF', nome: 'Franco Suíço', bid: 5.89, pctChange: 0.05, high: 5.94, low: 5.84), emoji: '🇨🇭'),
    (cotacao: const Cotacao(codigo: 'CAD', nome: 'Dólar Canadense', bid: 3.78, pctChange: 0.12, high: 3.82, low: 3.74), emoji: '🇨🇦'),
    (cotacao: const Cotacao(codigo: 'AUD', nome: 'Dólar Australiano', bid: 3.34, pctChange: -0.08, high: 3.38, low: 3.30), emoji: '🇦🇺'),
    (cotacao: const Cotacao(codigo: 'CNY', nome: 'Yuan Chinês', bid: 0.714, pctChange: 0.03, high: 0.718, low: 0.710), emoji: '🇨🇳'),
    (cotacao: const Cotacao(codigo: 'ARS', nome: 'Peso Argentino', bid: 0.00524, pctChange: -1.2, high: 0.00530, low: 0.00518), emoji: '🇦🇷'),
    (cotacao: const Cotacao(codigo: 'BTC', nome: 'Bitcoin', bid: 362800, pctChange: 2.15, high: 368000, low: 355000), emoji: '₿'),
    (cotacao: const Cotacao(codigo: 'ETH', nome: 'Ethereum', bid: 18420, pctChange: 1.87, high: 18900, low: 18100), emoji: 'Ξ'),
  ];
}
