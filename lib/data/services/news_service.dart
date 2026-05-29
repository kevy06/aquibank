import 'dart:convert';
import 'package:http/http.dart' as http;

class Noticia {
  final String titulo;
  final String descricao;
  final String fonte;
  final String url;
  final String? urlImagem;
  final DateTime publicadoEm;
  final List<String> tags;

  const Noticia({
    required this.titulo,
    required this.descricao,
    required this.fonte,
    required this.url,
    this.urlImagem,
    required this.publicadoEm,
    this.tags = const [],
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    return Noticia(
      titulo: json['title'] ?? '',
      descricao: json['description'] ?? json['content'] ?? '',
      fonte: json['source']?['name'] ?? 'Desconhecido',
      url: json['url'] ?? '',
      urlImagem: json['image'] ?? json['urlToImage'],
      publicadoEm: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class NewsService {
  static const _apiKey = String.fromEnvironment('GNEWS_API_KEY');
  static const _base = 'https://gnews.io/api/v4';

  Future<List<Noticia>> buscarNoticias({String tema = 'economia finanças'}) async {
    if (_apiKey.isEmpty) return _noticiasMock();

    final uri = Uri.parse(
      '$_base/search?q=${Uri.encodeComponent(tema)}'
      '&lang=pt&country=br&max=20&apikey=$_apiKey',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _noticiasMock();

      final data = json.decode(response.body);
      final articles = data['articles'] as List? ?? [];
      return articles.map((a) => Noticia.fromJson(a)).toList();
    } catch (_) {
      return _noticiasMock();
    }
  }

  List<Noticia> _noticiasMock() => [
        Noticia(
          titulo: 'Ibovespa fecha em alta com expectativa de queda de juros',
          descricao: 'O principal índice da bolsa brasileira registrou alta de 1,2% nesta sessão, impulsionado por expectativas de corte na taxa Selic. Analistas apontam que a melhora do cenário externo e dados positivos da inflação doméstica contribuíram para o movimento de alta.',
          fonte: 'InfoMoney',
          url: '',
          tags: ['economia', 'investimentos'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Noticia(
          titulo: 'Dólar recua frente ao real com fluxo externo positivo',
          descricao: 'A moeda americana caiu 0,8% em relação ao real, encerrando o dia cotada a R\$ 5,12, menor patamar em três semanas. O movimento foi impulsionado pela entrada de capital estrangeiro na bolsa e pelo enfraquecimento do dólar no mercado internacional.',
          fonte: 'Valor Econômico',
          url: '',
          tags: ['economia'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        Noticia(
          titulo: 'Nubank anuncia expansão para novos mercados na América Latina',
          descricao: 'A fintech brasileira confirmou planos de entrar em mais dois países da região até o final do ano, com investimento de R\$ 500 milhões. A empresa já conta com mais de 90 milhões de clientes no Brasil, México e Colômbia.',
          fonte: 'Exame',
          url: '',
          tags: ['fintech'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        Noticia(
          titulo: 'Bitcoin supera US\$ 70 mil e renova máxima histórica',
          descricao: 'A principal criptomoeda do mundo voltou a testar a resistência dos US\$ 70 mil, acumulando alta de 15% no mês. Especialistas apontam o aumento da demanda por ETFs de Bitcoin nos EUA como principal catalisador do movimento.',
          fonte: 'CoinTelegraph',
          url: '',
          tags: ['cripto', 'investimentos'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        Noticia(
          titulo: 'Selic deve cair para 10,5% até o fim do ano, aponta Focus',
          descricao: 'Analistas do mercado financeiro revisaram para baixo as projeções para a taxa básica de juros. A expectativa é de cortes graduais nas próximas reuniões do Copom, o que deve estimular o crédito e aquecer o consumo das famílias.',
          fonte: 'Banco Central',
          url: '',
          tags: ['economia'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 10)),
        ),
        Noticia(
          titulo: 'Ethereum sobe 20% após aprovação de ETF pela SEC',
          descricao: 'A segunda maior criptomoeda em valor de mercado disparou após a aprovação de fundos de investimento baseados em Ethereum pelos reguladores americanos, abrindo caminho para entrada de capital institucional.',
          fonte: 'CriptoFácil',
          url: '',
          tags: ['cripto'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        Noticia(
          titulo: 'PIB brasileiro cresce 2,1% no primeiro trimestre',
          descricao: 'O Produto Interno Bruto do Brasil avançou acima das expectativas, puxado pelo agronegócio e pela retomada do consumo das famílias. O resultado surpreendeu positivamente os economistas, que previam crescimento de 1,7%.',
          fonte: 'IBGE',
          url: '',
          tags: ['economia'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 14)),
        ),
        Noticia(
          titulo: 'Inter, C6 e PicPay disputam clientes com novas taxas zero',
          descricao: 'Fintechs apostam em benefícios e isenção de tarifas para atrair correntistas que buscam alternativas aos bancos tradicionais. A guerra por clientes já impacta os resultados dos grandes bancos, que respondem com contra-ofertas.',
          fonte: 'Seu Dinheiro',
          url: '',
          tags: ['fintech'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 18)),
        ),
        Noticia(
          titulo: 'Tesouro Direto bate recorde de investidores em 2026',
          descricao: 'O programa de renda fixa do governo federal atingiu 3,2 milhões de investidores ativos, novo recorde histórico. A alta da Selic e a facilidade de acesso digital são os principais fatores para o crescimento.',
          fonte: 'Tesouro Nacional',
          url: '',
          tags: ['investimentos'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 20)),
        ),
        Noticia(
          titulo: 'Open Finance: bancos devem integrar dados até dezembro',
          descricao: 'O Banco Central estabeleceu prazo final para que todas as instituições financeiras completem a integração com o sistema de Open Finance, permitindo portabilidade total de dados e serviços entre bancos e fintechs.',
          fonte: 'Fintech Report',
          url: '',
          tags: ['fintech', 'economia'],
          publicadoEm: DateTime.now().subtract(const Duration(hours: 24)),
        ),
      ];
}
