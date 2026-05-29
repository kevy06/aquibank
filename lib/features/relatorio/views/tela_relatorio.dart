import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/movimentacao.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/movimentacao_tile.dart';

class TelaRelatorio extends ConsumerStatefulWidget {
  const TelaRelatorio({super.key});

  @override
  ConsumerState<TelaRelatorio> createState() => _TelaRelatorioState();
}

class _TelaRelatorioState extends ConsumerState<TelaRelatorio>
    with AutomaticKeepAliveClientMixin {
  DateTime? _mesSelecionado;

  @override
  bool get wantKeepAlive => true;

  List<DateTime> _mesesParaFiltro(ContaState conta) {
    final hoje = DateTime.now();
    final atual = DateTime(hoje.year, hoje.month);
    final mapa = <String, DateTime>{chaveMes(atual): atual};
    for (final m in conta.mesesDisponiveis) {
      mapa[chaveMes(m)] = DateTime(m.year, m.month);
    }
    return mapa.values.toList()..sort((a, b) => b.compareTo(a));
  }

  DateTime _mesAtivo(List<DateTime> meses) {
    final sel = _mesSelecionado;
    if (sel == null) return meses.first;
    final existe = meses.any((m) => chaveMes(m) == chaveMes(sel));
    return existe ? sel : meses.first;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.isDark;
    final conta = ref.watch(contaProvider);
    final meses = _mesesParaFiltro(conta);
    final mes = _mesAtivo(meses);
    final movs = conta.doMes(mes.year, mes.month);
    final entradas = conta.entradasDoMes(mes.year, mes.month);
    final saidas = conta.saidasDoMes(mes.year, mes.month);
    final saldo = conta.saldoDoMes(mes.year, mes.month);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildCabecalho(context, isDark, mes)),
            SliverToBoxAdapter(child: _buildFiltroMes(context, isDark, meses, mes)),
            SliverToBoxAdapter(
              child: _buildResumo(context, isDark, entradas, saidas, saldo),
            ),
            SliverToBoxAdapter(
              child: _buildGrafico(context, conta, mes, movs.isEmpty),
            ),
            SliverToBoxAdapter(
              child: _buildCategorias(context, isDark, conta, mes),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Extrato do mês',
                        style: GoogleFonts.interTight(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.primaryLight : AppColors.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${movs.length} lançamentos',
                        style: GoogleFonts.interTight(
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (movs.isEmpty)
              SliverToBoxAdapter(child: _buildExtratoVazio(context, isDark))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i.isOdd) return const SizedBox(height: 10);
                    final mov = movs[i ~/ 2];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: MovimentacaoTile(
                        movimentacao: mov,
                        dataCompleta: true,
                        onExcluir: () =>
                            ref.read(contaProvider.notifier).excluir(mov.id),
                      ),
                    );
                  },
                  childCount: (movs.length * 2) - 1,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho(BuildContext context, bool isDark, DateTime mes) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.gradientPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatório',
                  style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  nomeMes(mes),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.query_stats_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildFiltroMes(
    BuildContext context,
    bool isDark,
    List<DateTime> meses,
    DateTime mesAtivo,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: chaveMes(mesAtivo),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Mês selecionado',
          prefixIcon: const Icon(Icons.calendar_month_rounded),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              width: 1.6,
            ),
          ),
        ),
        items: meses
            .map((m) => DropdownMenuItem(value: chaveMes(m), child: Text(nomeMes(m))))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          final partes = v.split('-');
          setState(() => _mesSelecionado =
              DateTime(int.parse(partes[0]), int.parse(partes[1])));
        },
      ),
    );
  }

  Widget _buildResumo(
    BuildContext context,
    bool isDark,
    double entradas,
    double saidas,
    double saldo,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ResumoTile(
              label: 'Entradas',
              valor: formatarMoeda(entradas),
              cor: AppColors.income,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumoTile(
              label: 'Saídas',
              valor: formatarMoeda(saidas),
              cor: AppColors.expense,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumoTile(
              label: 'Saldo',
              valor: formatarMoeda(saldo),
              cor: saldo >= 0
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : AppColors.expense,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrafico(
    BuildContext context,
    ContaState conta,
    DateTime mes,
    bool vazio,
  ) {
    final entradasDiarias =
        conta.totaisDiariosDoMes(mes.year, mes.month, TipoMovimentacao.entrada);
    final saidasDiarias =
        conta.totaisDiariosDoMes(mes.year, mes.month, TipoMovimentacao.saida);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;

    var maxY = 0.0;
    for (final v in [...entradasDiarias.values, ...saidasDiarias.values]) {
      if (v > maxY) maxY = v;
    }
    final intervalo = maxY <= 0 ? 100.0 : maxY * 1.25;

    final grupos = List.generate(ultimoDia, (i) {
      final dia = i + 1;
      final eVal = entradasDiarias[dia] ?? 0;
      final sVal = saidasDiarias[dia] ?? 0;
      return BarChartGroupData(
        x: dia,
        barsSpace: 3,
        barRods: [
          BarChartRodData(
            toY: eVal,
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF00A876), Color(0xFF00FFB3)],
            ),
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            backDrawRodData: BackgroundBarChartRodData(
              show: eVal > 0,
              toY: eVal,
              color: Color(0xFF00C896).withValues(alpha: 0.18),
            ),
          ),
          BarChartRodData(
            toY: sVal,
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFFCC3030), Color(0xFFFF7070)],
            ),
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            backDrawRodData: BackgroundBarChartRodData(
              show: sVal > 0,
              toY: sVal,
              color: Color(0xFFFF5252).withValues(alpha: 0.18),
            ),
          ),
        ],
      );
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF060F1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fluxo do mês',
                  style: GoogleFonts.interTight(
                    color: AppColors.textPrimaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const _LegendaGrafico(cor: Color(0xFF00FFB3), texto: 'Entrada'),
              const SizedBox(width: 10),
              const _LegendaGrafico(cor: Color(0xFFFF7070), texto: 'Saída'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: vazio
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          color: AppColors.textSecondaryDark,
                          size: 42,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sem dados para este mês',
                          style: GoogleFonts.interTight(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceBetween,
                      minY: 0,
                      maxY: intervalo,
                      barGroups: grupos,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: intervalo / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.borderDark.withValues(alpha: 0.5),
                          strokeWidth: 0.5,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF0D1B2E),
                          getTooltipItem: (g, _, rod, ri) => BarTooltipItem(
                            '${ri == 0 ? "Entrada" : "Saída"}\n${formatarMoeda(rod.toY)}',
                            GoogleFonts.interTight(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
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
                            reservedSize: 46,
                            interval: intervalo / 4,
                            getTitlesWidget: (v, _) => Text(
                              formatarValorCompacto(v),
                              style: GoogleFonts.interTight(
                                color: AppColors.textSecondaryDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (v, _) {
                              final d = v.toInt();
                              if (d == 1 || d == ultimoDia || d % 5 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '$d',
                                    style: GoogleFonts.interTight(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 9,
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

  static const _catColors = [
    AppColors.expense,
    Color(0xFFFF7043),
    AppColors.warning,
    AppColors.income,
    AppColors.primaryLight,
  ];

  Widget _buildCategorias(
    BuildContext context,
    bool isDark,
    ContaState conta,
    DateTime mes,
  ) {
    final cats = conta.categoriasDoMes(mes.year, mes.month, TipoMovimentacao.saida);
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.values.fold(0.0, (s, v) => s + v);
    final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categorias de despesa',
            style: GoogleFonts.interTight(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Top 5 maiores gastos do mês',
            style: GoogleFonts.interTight(
              color: context.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 52,
                      sections: top.asMap().entries.map((e) {
                        final pct = total > 0 ? e.value.value / total : 0.0;
                        return PieChartSectionData(
                          color: _catColors[e.key % _catColors.length],
                          value: e.value.value,
                          title: '${(pct * 100).toStringAsFixed(0)}%',
                          radius: 44,
                          titleStyle: GoogleFonts.interTight(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: top.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _catColors[e.key % _catColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                e.value.key,
                                style: GoogleFonts.interTight(
                                  color: context.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...top.asMap().entries.map((e) {
            final pct = total > 0 ? e.value.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _catColors[e.key % _catColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.key,
                          style: GoogleFonts.interTight(
                            color: context.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        formatarMoeda(e.value.value),
                        style: GoogleFonts.interTight(
                          color: _catColors[e.key % _catColors.length],
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      backgroundColor:
                          isDark ? AppColors.borderDark : const Color(0xFFEAF0FA),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _catColors[e.key % _catColors.length],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.interTight(
                      color: context.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExtratoVazio(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, color: context.accent, size: 40),
            const SizedBox(height: 12),
            Text(
              'Nenhum lançamento neste mês',
              textAlign: TextAlign.center,
              style: GoogleFonts.interTight(
                color: context.textPrimary,
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

class _ResumoTile extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final bool isDark;
  const _ResumoTile({
    required this.label,
    required this.valor,
    required this.cor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            label == 'Entradas'
                ? Icons.south_west_rounded
                : label == 'Saídas'
                    ? Icons.north_east_rounded
                    : Icons.account_balance_rounded,
            color: cor,
            size: 22,
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.interTight(
              color: context.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: GoogleFonts.interTight(
                color: cor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: GoogleFonts.interTight(
            color: AppColors.textSecondaryDark,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
