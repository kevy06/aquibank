import 'package:flutter/material.dart';

import '../modelos/movimentacao.dart';

class ContaGerenciador extends ChangeNotifier {
  final List<Movimentacao> _movimentacoes = [];

  List<Movimentacao> get movimentacoes => List.unmodifiable(_movimentacoes);

  List<Movimentacao> get ultimasMovimentacoes {
    final lista = List<Movimentacao>.from(_movimentacoes);
    lista.sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  double get entradas => _totalPorTipo(_movimentacoes, TipoMovimentacao.entrada);

  double get saidas => _totalPorTipo(_movimentacoes, TipoMovimentacao.saida);

  double get saldoAtual => entradas - saidas;

  Map<String, double> get saidasPorCategoria =>
      _categoriasPorTipo(_movimentacoes, TipoMovimentacao.saida);

  Map<String, double> get entradasPorCategoria =>
      _categoriasPorTipo(_movimentacoes, TipoMovimentacao.entrada);

  List<DateTime> get ultimos6Meses {
    final agora = DateTime.now();
    return List.generate(
      6,
      (i) => DateTime(agora.year, agora.month - (5 - i)),
    );
  }

  List<DateTime> get mesesDisponiveis {
    final meses = <String, DateTime>{};
    for (final m in _movimentacoes) {
      final chave = '${m.data.year}-${m.data.month.toString().padLeft(2, '0')}';
      meses[chave] = DateTime(m.data.year, m.data.month);
    }
    final lista = meses.values.toList()..sort((a, b) => b.compareTo(a));
    return lista;
  }

  List<Movimentacao> movimentacoesDoMes(int ano, int mes) {
    return _movimentacoes
        .where((m) => m.data.year == ano && m.data.month == mes)
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  List<Movimentacao> movimentacoesDoMesSelecionado(DateTime mes) {
    return movimentacoesDoMes(mes.year, mes.month);
  }

  double entradasDoMes(int ano, int mes) {
    return _totalPorTipo(movimentacoesDoMes(ano, mes), TipoMovimentacao.entrada);
  }

  double saidasDoMes(int ano, int mes) {
    return _totalPorTipo(movimentacoesDoMes(ano, mes), TipoMovimentacao.saida);
  }

  double saldoDoMes(int ano, int mes) {
    return entradasDoMes(ano, mes) - saidasDoMes(ano, mes);
  }

  double entradasDoMesSelecionado(DateTime mes) {
    return entradasDoMes(mes.year, mes.month);
  }

  double saidasDoMesSelecionado(DateTime mes) {
    return saidasDoMes(mes.year, mes.month);
  }

  double saldoDoMesSelecionado(DateTime mes) {
    return saldoDoMes(mes.year, mes.month);
  }

  Map<String, double> categoriasDoMes(DateTime mes, TipoMovimentacao tipo) {
    return _categoriasPorTipo(movimentacoesDoMesSelecionado(mes), tipo);
  }

  Map<int, double> totaisDiariosDoMes(DateTime mes, TipoMovimentacao tipo) {
    final totais = <int, double>{};
    for (final m in movimentacoesDoMesSelecionado(mes)) {
      if (m.tipo == tipo) {
        totais[m.data.day] = (totais[m.data.day] ?? 0) + m.valor;
      }
    }
    return totais;
  }

  void novaMovimentacao({
    required String titulo,
    required double valor,
    required TipoMovimentacao tipo,
    required String categoria,
    DateTime? data,
  }) {
    final mov = Movimentacao(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      titulo: titulo,
      valor: valor,
      tipo: tipo,
      data: data ?? DateTime.now(),
      categoria: categoria,
    );
    _movimentacoes.add(mov);
    notifyListeners();
  }

  void excluirMovimentacao(String id) {
    _movimentacoes.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void carregarExemplos() {
    if (_movimentacoes.isNotEmpty) return;

    final exemplos = <_MovimentacaoExemplo>[
      const _MovimentacaoExemplo('Salário mensal', 4500, TipoMovimentacao.entrada, 0, 1, 'Salário'),
      const _MovimentacaoExemplo('Projeto freelancer', 800, TipoMovimentacao.entrada, 0, 8, 'Freelance'),
      const _MovimentacaoExemplo('Venda online', 250, TipoMovimentacao.entrada, 0, 12, 'Vendas'),
      const _MovimentacaoExemplo('Aluguel apartamento', 1200, TipoMovimentacao.saida, 0, 2, 'Moradia'),
      const _MovimentacaoExemplo('Mercado da semana', 380, TipoMovimentacao.saida, 0, 10, 'Alimentação'),
      const _MovimentacaoExemplo('Energia elétrica', 210, TipoMovimentacao.saida, 0, 6, 'Contas'),
      const _MovimentacaoExemplo('Transporte por app', 150, TipoMovimentacao.saida, 0, 15, 'Transporte'),
      const _MovimentacaoExemplo('Assinaturas digitais', 45.90, TipoMovimentacao.saida, 0, 18, 'Assinaturas'),
      const _MovimentacaoExemplo('Salário mensal', 4500, TipoMovimentacao.entrada, -1, 5, 'Salário'),
      const _MovimentacaoExemplo('Freelance app mobile', 600, TipoMovimentacao.entrada, -1, 18, 'Freelance'),
      const _MovimentacaoExemplo('Aluguel', 1200, TipoMovimentacao.saida, -1, 3, 'Moradia'),
      const _MovimentacaoExemplo('Supermercado', 420, TipoMovimentacao.saida, -1, 10, 'Alimentação'),
      const _MovimentacaoExemplo('Conta de luz', 198, TipoMovimentacao.saida, -1, 8, 'Contas'),
      const _MovimentacaoExemplo('Uber e ônibus', 89, TipoMovimentacao.saida, -1, 15, 'Transporte'),
      const _MovimentacaoExemplo('Streaming', 65.90, TipoMovimentacao.saida, -1, 12, 'Assinaturas'),
      const _MovimentacaoExemplo('Salário mensal', 4500, TipoMovimentacao.entrada, -2, 5, 'Salário'),
      const _MovimentacaoExemplo('Aluguel', 1200, TipoMovimentacao.saida, -2, 3, 'Moradia'),
      const _MovimentacaoExemplo('Supermercado', 350, TipoMovimentacao.saida, -2, 12, 'Alimentação'),
      const _MovimentacaoExemplo('Conta de energia', 205, TipoMovimentacao.saida, -2, 7, 'Contas'),
      const _MovimentacaoExemplo('Internet', 89.90, TipoMovimentacao.saida, -2, 5, 'Contas'),
      const _MovimentacaoExemplo('Jantar restaurante', 120, TipoMovimentacao.saida, -2, 22, 'Alimentação'),
      const _MovimentacaoExemplo('Salário mensal', 4500, TipoMovimentacao.entrada, -3, 5, 'Salário'),
      const _MovimentacaoExemplo('Bônus empresa', 1000, TipoMovimentacao.entrada, -3, 15, 'Salário'),
      const _MovimentacaoExemplo('Aluguel', 1200, TipoMovimentacao.saida, -3, 3, 'Moradia'),
      const _MovimentacaoExemplo('Supermercado', 310, TipoMovimentacao.saida, -3, 9, 'Alimentação'),
      const _MovimentacaoExemplo('Viagem final de semana', 800, TipoMovimentacao.saida, -3, 20, 'Outros'),
      const _MovimentacaoExemplo('Contas do mês', 290, TipoMovimentacao.saida, -3, 7, 'Contas'),
      const _MovimentacaoExemplo('Salário mensal', 4500, TipoMovimentacao.entrada, -4, 5, 'Salário'),
      const _MovimentacaoExemplo('13º salário', 2250, TipoMovimentacao.entrada, -4, 2, 'Salário'),
      const _MovimentacaoExemplo('Aluguel', 1200, TipoMovimentacao.saida, -4, 3, 'Moradia'),
      const _MovimentacaoExemplo('IPTU', 380, TipoMovimentacao.saida, -4, 10, 'Contas'),
      const _MovimentacaoExemplo('Supermercado', 430, TipoMovimentacao.saida, -4, 16, 'Alimentação'),
      const _MovimentacaoExemplo('Contas do mês', 220, TipoMovimentacao.saida, -4, 7, 'Contas'),
      const _MovimentacaoExemplo('Salário mensal', 4500, TipoMovimentacao.entrada, -5, 5, 'Salário'),
      const _MovimentacaoExemplo('Venda de equipamentos', 700, TipoMovimentacao.entrada, -5, 18, 'Vendas'),
      const _MovimentacaoExemplo('Aluguel', 1200, TipoMovimentacao.saida, -5, 3, 'Moradia'),
      const _MovimentacaoExemplo('Supermercado', 390, TipoMovimentacao.saida, -5, 14, 'Alimentação'),
      const _MovimentacaoExemplo('Contas do mês', 210, TipoMovimentacao.saida, -5, 7, 'Contas'),
      const _MovimentacaoExemplo('Assinaturas digitais', 65.90, TipoMovimentacao.saida, -5, 10, 'Assinaturas'),
    ];

    _movimentacoes.addAll(
      exemplos.asMap().entries.map((entry) {
        final exemplo = entry.value;
        return Movimentacao(
          id: 'exemplo_${entry.key}',
          titulo: exemplo.titulo,
          valor: exemplo.valor,
          tipo: exemplo.tipo,
          data: _dataRelativa(exemplo.deslocamentoMes, exemplo.dia),
          categoria: exemplo.categoria,
        );
      }),
    );
    notifyListeners();
  }

  double _totalPorTipo(List<Movimentacao> lista, TipoMovimentacao tipo) {
    return lista
        .where((m) => m.tipo == tipo)
        .fold(0.0, (total, m) => total + m.valor);
  }

  Map<String, double> _categoriasPorTipo(
    List<Movimentacao> lista,
    TipoMovimentacao tipo,
  ) {
    final mapa = <String, double>{};
    for (final m in lista) {
      if (m.tipo == tipo) {
        mapa[m.categoria] = (mapa[m.categoria] ?? 0) + m.valor;
      }
    }
    return mapa;
  }

  DateTime _dataRelativa(int deslocamentoMes, int dia) {
    final agora = DateTime.now();
    final base = DateTime(agora.year, agora.month + deslocamentoMes);
    final ultimoDia = DateTime(base.year, base.month + 1, 0).day;
    final diaSeguro = dia > ultimoDia ? ultimoDia : dia;
    return DateTime(base.year, base.month, diaSeguro);
  }
}

class _MovimentacaoExemplo {
  final String titulo;
  final double valor;
  final TipoMovimentacao tipo;
  final int deslocamentoMes;
  final int dia;
  final String categoria;

  const _MovimentacaoExemplo(
    this.titulo,
    this.valor,
    this.tipo,
    this.deslocamentoMes,
    this.dia,
    this.categoria,
  );
}
