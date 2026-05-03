enum TipoMovimentacao { entrada, saida }

class Movimentacao {
  final String id;
  final String titulo;
  final double valor;
  final TipoMovimentacao tipo;
  final DateTime data;
  final String categoria;

  Movimentacao({
    required this.id,
    required this.titulo,
    required this.valor,
    required this.tipo,
    required this.data,
    required this.categoria,
  });
}
