enum TipoMovimentacao { entrada, saida }

class Movimentacao {
  final String id;
  final String usuarioId; // UUID (Supabase Auth UID)
  final String titulo;
  final double valor;
  final TipoMovimentacao tipo;
  final String categoria;
  final String? descricao;
  final DateTime data;
  final DateTime criadoEm;

  const Movimentacao({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.valor,
    required this.tipo,
    required this.categoria,
    this.descricao,
    required this.data,
    required this.criadoEm,
  });

  Movimentacao copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    double? valor,
    TipoMovimentacao? tipo,
    String? categoria,
    String? descricao,
    DateTime? data,
    DateTime? criadoEm,
  }) {
    return Movimentacao(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      descricao: descricao ?? this.descricao,
      data: data ?? this.data,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'usuario_id': usuarioId,
    'titulo': titulo,
    'valor': valor,
    'tipo': tipo.name,
    'categoria': categoria,
    if (descricao != null) 'descricao': descricao,
    'data':
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
    'criado_em': criadoEm.toIso8601String(),
  };

  factory Movimentacao.fromMap(Map<String, dynamic> map) => Movimentacao(
    id: map['id'] as String,
    usuarioId: map['usuario_id'] as String,
    titulo: map['titulo'] as String,
    valor: (map['valor'] as num).toDouble(),
    tipo: TipoMovimentacao.values.byName(map['tipo'] as String),
    categoria: map['categoria'] as String,
    descricao: map['descricao'] as String?,
    data: DateTime.parse(map['data'] as String),
    criadoEm: DateTime.parse(
      (map['criado_em'] ?? map['created_at'] ?? DateTime.now().toIso8601String()) as String,
    ),
  );

  static const categoriasEntrada = [
    'Salário',
    'Freelance',
    'Vendas',
    'Investimentos',
    'Bônus',
    'Outros',
  ];

  static const categoriasSaida = [
    'Alimentação',
    'Moradia',
    'Transporte',
    'Assinaturas',
    'Contas',
    'Compras',
    'Saúde',
    'Lazer',
    'Outros',
  ];

  static List<String> categoriasParaTipo(TipoMovimentacao tipo) =>
      tipo == TipoMovimentacao.entrada ? categoriasEntrada : categoriasSaida;
}
