import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../gerenciadores/conta_gerenciador.dart';
import '../modelos/movimentacao.dart';

class TelaRelatorio extends StatefulWidget {
  const TelaRelatorio({super.key});

  @override
  State<TelaRelatorio> createState() => _TelaRelatorioState();
}

class _TelaRelatorioState extends State<TelaRelatorio> {
  static const _azul = Color(0xFF0D47A1);
  static const _azulClaro = Color(0xFF2979FF);
  static const _fundo = Color(0xFFF3F7FE);
  static const _texto = Color(0xFF10243E);
  static const _textoSuave = Color(0xFF6B7A90);
  static const _entrada = Color(0xFF0F8F6D);
  static const _saida = Color(0xFFE65100);

  DateTime? _mesSelecionado;

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatoData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _fundo,
      body: Consumer<ContaGerenciador>(
        builder: (context, contaVM, _) {
          final meses = _mesesParaFiltro(contaVM);
          final mesAtivo = _mesAtivo(meses);
          final movimentacoes = contaVM.movimentacoesDoMesSelecionado(mesAtivo);
          final entradas = contaVM.entradasDoMesSelecionado(mesAtivo);
          final saidas = contaVM.saidasDoMesSelecionado(mesAtivo);
          final saldo = contaVM.saldoDoMesSelecionado(mesAtivo);

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderRelatorio(
                    mes: mesAtivo,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FiltroMensal(
                    meses: meses,
                    mesSelecionado: mesAtivo,
                    onChanged: (mes) => setState(() => _mesSelecionado = mes),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ResumoMensal(
                    formatoMoeda: formatoMoeda,
                    entradas: entradas,
                    saidas: saidas,
                    saldo: saldo,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _GraficoMensal(
                    contaVM: contaVM,
                    mes: mesAtivo,
                    vazio: movimentacoes.isEmpty,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoriasDoMes(
                    contaVM: contaVM,
                    mes: mesAtivo,
                    formatoMoeda: formatoMoeda,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: _TituloSecao(
                            titulo: 'Extrato filtrado',
                            subtitulo: 'Lançamentos do mês selecionado',
                          ),
                        ),
                        Text(
                          '${movimentacoes.length}',
                          style: const TextStyle(
                            color: _azul,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (movimentacoes.isEmpty)
                  const SliverToBoxAdapter(child: _ExtratoVazio())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) return const SizedBox(height: 10);
                        final mov = movimentacoes[index ~/ 2];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ExtratoTile(
                            movimentacao: mov,
                            formatoMoeda: formatoMoeda,
                            formatoData: formatoData,
                            onExcluir: () => _excluirMovimentacao(
                              context,
                              contaVM,
                              mov,
                            ),
                          ),
                        );
                      },
                      childCount: (movimentacoes.length * 2) - 1,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DateTime> _mesesParaFiltro(ContaGerenciador contaVM) {
    final hoje = DateTime.now();
    final atual = DateTime(hoje.year, hoje.month);
    final mapa = <String, DateTime>{_chaveMes(atual): atual};

    for (final mes in contaVM.mesesDisponiveis) {
      mapa[_chaveMes(mes)] = DateTime(mes.year, mes.month);
    }

    final meses = mapa.values.toList()..sort((a, b) => b.compareTo(a));
    return meses;
  }

  DateTime _mesAtivo(List<DateTime> meses) {
    final selecionado = _mesSelecionado;
    if (selecionado == null) return meses.first;

    final existe = meses.any((mes) => _chaveMes(mes) == _chaveMes(selecionado));
    return existe ? selecionado : meses.first;
  }

  void _excluirMovimentacao(
    BuildContext context,
    ContaGerenciador contaVM,
    Movimentacao movimentacao,
  ) {
    contaVM.excluirMovimentacao(movimentacao.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${movimentacao.titulo} excluído'),
        backgroundColor: _azul,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _HeaderRelatorio extends StatelessWidget {
  final DateTime mes;
  final VoidCallback onBack;

  const _HeaderRelatorio({required this.mes, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _TelaRelatorioState._azul,
            Color(0xFF1565C0),
            _TelaRelatorioState._azulClaro,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _TelaRelatorioState._azul.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relatório',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _nomeMes(mes),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.query_stats_rounded, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

class _FiltroMensal extends StatelessWidget {
  final List<DateTime> meses;
  final DateTime mesSelecionado;
  final ValueChanged<DateTime> onChanged;

  const _FiltroMensal({
    required this.meses,
    required this.mesSelecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TituloSecao(
            titulo: 'Filtro mensal',
            subtitulo: 'Escolha o mês do extrato',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _chaveMes(mesSelecionado),
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.calendar_month_rounded,
                color: _TelaRelatorioState._azul,
              ),
              filled: true,
              fillColor: const Color(0xFFF6F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE2EAF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE2EAF7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: _TelaRelatorioState._azul,
                  width: 1.6,
                ),
              ),
            ),
            items: meses
                .map(
                  (mes) => DropdownMenuItem<String>(
                    value: _chaveMes(mes),
                    child: Text(_nomeMes(mes)),
                  ),
                )
                .toList(),
            onChanged: (valor) {
              if (valor == null) return;
              final partes = valor.split('-');
              onChanged(DateTime(int.parse(partes[0]), int.parse(partes[1])));
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
            label: const Text('Baixar extrato'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _TelaRelatorioState._azul,
              side: const BorderSide(color: _TelaRelatorioState._azul),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoMensal extends StatelessWidget {
  final NumberFormat formatoMoeda;
  final double entradas;
  final double saidas;
  final double saldo;

  const _ResumoMensal({
    required this.formatoMoeda,
    required this.entradas,
    required this.saidas,
    required this.saldo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ResumoTile(
              label: 'Entradas',
              value: formatoMoeda.format(entradas),
              icon: Icons.south_west_rounded,
              color: _TelaRelatorioState._entrada,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumoTile(
              label: 'Saídas',
              value: formatoMoeda.format(saidas),
              icon: Icons.north_east_rounded,
              color: _TelaRelatorioState._saida,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumoTile(
              label: 'Saldo',
              value: formatoMoeda.format(saldo),
              icon: Icons.account_balance_rounded,
              color: saldo >= 0
                  ? _TelaRelatorioState._azul
                  : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ResumoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: _TelaRelatorioState._textoSuave,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoMensal extends StatelessWidget {
  final ContaGerenciador contaVM;
  final DateTime mes;
  final bool vazio;

  const _GraficoMensal({
    required this.contaVM,
    required this.mes,
    required this.vazio,
  });

  @override
  Widget build(BuildContext context) {
    final entradas = contaVM.totaisDiariosDoMes(mes, TipoMovimentacao.entrada);
    final saidas = contaVM.totaisDiariosDoMes(mes, TipoMovimentacao.saida);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
    var maiorValor = 0.0;

    for (final valor in [...entradas.values, ...saidas.values]) {
      if (valor > maiorValor) maiorValor = valor;
    }

    final maxY = maiorValor <= 0 ? 100.0 : maiorValor * 1.25;
    final intervalo = maxY / 4;
    final grupos = List.generate(ultimoDia, (index) {
      final dia = index + 1;
      return BarChartGroupData(
        x: dia,
        barsSpace: 3,
        barRods: [
          BarChartRodData(
            toY: entradas[dia] ?? 0,
            color: _TelaRelatorioState._entrada,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
          BarChartRodData(
            toY: saidas[dia] ?? 0,
            color: _TelaRelatorioState._saida,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      );
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _TituloSecao(
                  titulo: 'Fluxo do mês',
                  subtitulo: 'Entradas e saídas por dia',
                ),
              ),
              const _LegendaGrafico(
                cor: _TelaRelatorioState._entrada,
                texto: 'Entrada',
              ),
              const SizedBox(width: 10),
              const _LegendaGrafico(
                cor: _TelaRelatorioState._saida,
                texto: 'Saída',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 250,
            child: vazio
                ? const _GraficoVazio()
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceBetween,
                      minY: 0,
                      maxY: maxY,
                      barGroups: grupos,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: intervalo,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(0xFFEAF0FA),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final tipo = rodIndex == 0 ? 'Entrada' : 'Saída';
                            return BarTooltipItem(
                              '$tipo\nR\$ ${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: intervalo,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _valorCompacto(value),
                                style: const TextStyle(
                                  color: _TelaRelatorioState._textoSuave,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final dia = value.toInt();
                              if (dia == 1 || dia == ultimoDia || dia % 5 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '$dia',
                                    style: const TextStyle(
                                      color: _TelaRelatorioState._textoSuave,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoriasDoMes extends StatelessWidget {
  final ContaGerenciador contaVM;
  final DateTime mes;
  final NumberFormat formatoMoeda;

  const _CategoriasDoMes({
    required this.contaVM,
    required this.mes,
    required this.formatoMoeda,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = contaVM.categoriasDoMes(mes, TipoMovimentacao.saida);
    final total = categorias.values.fold(0.0, (soma, valor) => soma + valor);
    final entradas = categorias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entradas.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TituloSecao(
            titulo: 'Categorias',
            subtitulo: 'Maiores despesas do mês',
          ),
          const SizedBox(height: 14),
          ...entradas.take(5).map((entry) {
            final pct = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoriaLinha(
                nome: entry.key,
                valor: formatoMoeda.format(entry.value),
                pct: pct,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoriaLinha extends StatelessWidget {
  final String nome;
  final String valor;
  final double pct;

  const _CategoriaLinha({
    required this.nome,
    required this.valor,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(
                  color: _TelaRelatorioState._texto,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              valor,
              style: const TextStyle(
                color: _TelaRelatorioState._saida,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: const Color(0xFFEAF0FA),
            valueColor: const AlwaysStoppedAnimation<Color>(
              _TelaRelatorioState._saida,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExtratoTile extends StatelessWidget {
  final Movimentacao movimentacao;
  final NumberFormat formatoMoeda;
  final DateFormat formatoData;
  final VoidCallback onExcluir;

  const _ExtratoTile({
    required this.movimentacao,
    required this.formatoMoeda,
    required this.formatoData,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final entrada = movimentacao.tipo == TipoMovimentacao.entrada;
    final cor =
        entrada ? _TelaRelatorioState._entrada : _TelaRelatorioState._saida;

    return Dismissible(
      key: Key(movimentacao.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onExcluir(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5ECF7)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                entrada ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: cor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movimentacao.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _TelaRelatorioState._texto,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        movimentacao.categoria,
                        style: const TextStyle(
                          color: _TelaRelatorioState._textoSuave,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formatoData.format(movimentacao.data),
                        style: const TextStyle(
                          color: Color(0xFF9AA8BB),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${entrada ? '+' : '-'} ${formatoMoeda.format(movimentacao.valor)}',
                  style: TextStyle(
                    color: cor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendaGrafico extends StatelessWidget {
  final Color cor;
  final String texto;

  const _LegendaGrafico({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          texto,
          style: const TextStyle(
            color: _TelaRelatorioState._textoSuave,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _TituloSecao({required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: _TelaRelatorioState._texto,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitulo,
          style: const TextStyle(
            color: _TelaRelatorioState._textoSuave,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GraficoVazio extends StatelessWidget {
  const _GraficoVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECF7)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            color: _TelaRelatorioState._azul,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'Sem dados para este mês',
            style: TextStyle(
              color: _TelaRelatorioState._texto,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtratoVazio extends StatelessWidget {
  const _ExtratoVazio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5ECF7)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: _TelaRelatorioState._azul,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum lançamento no mês selecionado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _TelaRelatorioState._texto,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _chaveMes(DateTime mes) {
  return '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
}

String _nomeMes(DateTime mes) {
  const nomes = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${nomes[mes.month - 1]} ${mes.year}';
}

String _valorCompacto(double value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toStringAsFixed(0);
}
