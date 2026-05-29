import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/movimentacao.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/movimentacao_tile.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../../app/views/main_app.dart';
import '../../relatorio/views/tela_relatorio.dart';

class TelaHome extends ConsumerStatefulWidget {
  const TelaHome({super.key});

  @override
  ConsumerState<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends ConsumerState<TelaHome>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _saldoOculto = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.isDark;
    final conta = ref.watch(contaProvider);
    final auth = ref.watch(authProvider);
    final hoje = DateTime.now();

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: conta.isLoading
                ? _buildShimmer()
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(auth, isDark)),
                      SliverToBoxAdapter(child: _buildSaldoCard(conta, isDark, auth)),
                      SliverToBoxAdapter(child: _buildAcoesRapidas(context)),
                      SliverToBoxAdapter(child: _buildResumoMes(conta, hoje, isDark, _saldoOculto)),
                      SliverToBoxAdapter(child: _buildMiniGrafico(conta, hoje)),
                      SliverToBoxAdapter(child: _buildCabecalhoUltimas(context, isDark)),
                      if (conta.ordenadas.isEmpty)
                        SliverToBoxAdapter(child: _buildVazio(isDark))
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              if (i.isOdd) return const SizedBox(height: 10);
                              final idx = i ~/ 2;
                              if (idx >= conta.ordenadas.take(6).length) return null;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: MovimentacaoTile(movimentacao: conta.ordenadas[idx]),
                              );
                            },
                            childCount: (conta.ordenadas.take(6).length * 2) - 1,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() => const SingleChildScrollView(
    padding: EdgeInsets.only(top: 16),
    child: Column(children: [
      ShimmerCard(height: 70, width: double.infinity),
      SizedBox(height: 16),
      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ShimmerCard(height: 240)),
      SizedBox(height: 16),
      ShimmerList(count: 5),
    ]),
  );

  Widget _buildHeader(AuthState auth, bool isDark) {
    final foto = ref.watch(fotoPerfilProvider);
    final notifs = ref.watch(notificacaoProvider);
    final naoLidas = notifs.where((n) => !n.lida).length;
    final iniciais = (auth.nomeUsuario ?? 'U').trim().split(' ')
        .take(2).map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: foto == null ? const LinearGradient(colors: AppColors.gradientPrimary) : null,
                shape: BoxShape.circle,
                image: foto != null
                    ? DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(foto) as ImageProvider
                            : FileImage(File(foto)),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: foto == null
                  ? Center(
                      child: Text(
                        iniciais.isEmpty ? 'U' : iniciais,
                        style: GoogleFonts.interTight(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${saudacao()}, ${auth.nomeUsuario?.split(' ').first ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.interTight(
                    color: context.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Sua dashboard financeira',
                  style: GoogleFonts.interTight(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderBtn(
                icon: naoLidas > 0 ? Icons.notifications_rounded : Icons.notifications_outlined,
                isDark: isDark,
                onTap: () => _abrirNotificacoes(notifs),
              ),
              if (naoLidas > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.expense,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.bgDark : AppColors.bgLight,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        naoLidas > 9 ? '9+' : '$naoLidas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirNotificacoes(List<AppNotificacao> notifs) {
    ref.read(notificacaoProvider.notifier).marcarTodasLidas();
    final isDark = context.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Notificações',
                    style: GoogleFonts.interTight(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (notifs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma notificação',
                      style: GoogleFonts.interTight(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    height: 1,
                  ),
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        n.titulo,
                        style: GoogleFonts.interTight(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: Text(
                        n.mensagem,
                        style: GoogleFonts.interTight(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard(ContaState conta, bool isDark, AuthState auth) {
    final hoje = DateTime.now();
    final entradasMes = conta.entradasDoMes(hoje.year, hoje.month);
    final saidasMes = conta.saidasDoMes(hoje.year, hoje.month);
    final cardSuffix = '${(auth.usuarioId ?? '').hashCode.abs() % 9000 + 1000}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientCard,
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.28),
              blurRadius: 36,
              spreadRadius: -4,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 64,
              spreadRadius: -12,
              offset: const Offset(0, 28),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Top-right glow orb
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom-left glow orb
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.electricBlue.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Top accent stripe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primaryLight,
                      AppColors.electricBlue,
                      AppColors.primaryLight,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // EMV chip
                      Container(
                        width: 36,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB8862A), Color(0xFFEDC040), Color(0xFFB8862A)],
                            stops: [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4A843).withValues(alpha: 0.45),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 8,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 0.8,
                                  color: Colors.black.withValues(alpha: 0.18),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 9,
                                child: Container(
                                  height: 0.8,
                                  color: Colors.black.withValues(alpha: 0.18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AquiBank',
                            style: GoogleFonts.interTight(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setState(() => _saldoOculto = !_saldoOculto),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Icon(
                                _saldoOculto
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.white.withValues(alpha: 0.75),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Saldo disponível',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _saldoOculto
                        ? Text(
                            '•••••••',
                            key: const ValueKey('hidden'),
                            style: GoogleFonts.interTight(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : FittedBox(
                            key: ValueKey(conta.saldoAtual),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatarMoeda(conta.saldoAtual),
                              style: GoogleFonts.interTight(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: AppColors.primaryLight.withValues(alpha: 0.60),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '•••• •••• •••• $cardSuffix',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SaldoMetrica(
                          label: 'Entradas',
                          valor: _saldoOculto ? '•••' : formatarMoeda(entradasMes),
                          icon: Icons.south_west_rounded,
                          cor: AppColors.income,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: _SaldoMetrica(
                          label: 'Saídas',
                          valor: _saldoOculto ? '•••' : formatarMoeda(saidasMes),
                          icon: Icons.north_east_rounded,
                          cor: AppColors.expense,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcoesRapidas(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _AcaoBtn(
              label: 'Entrada',
              icon: Icons.south_west_rounded,
              cor: AppColors.income,
              isDark: context.isDark,
              onTap: () => abrirFormularioLancamento(
                context, ref,
                tipoInicial: TipoMovimentacao.entrada,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AcaoBtn(
              label: 'Despesa',
              icon: Icons.north_east_rounded,
              cor: AppColors.expense,
              isDark: context.isDark,
              onTap: () => abrirFormularioLancamento(
                context, ref,
                tipoInicial: TipoMovimentacao.saida,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AcaoBtn(
              label: 'Transferir',
              icon: Icons.swap_horiz_rounded,
              cor: AppColors.primaryLight,
              isDark: context.isDark,
              onTap: () => abrirFormularioLancamento(context, ref),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AcaoBtn(
              label: 'Análise',
              icon: Icons.query_stats_rounded,
              cor: const Color(0xFF9C27B0),
              isDark: context.isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TelaRelatorio()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoMes(ContaState conta, DateTime hoje, bool isDark, bool ocultarValores) {
    final entradas = conta.entradasDoMes(hoje.year, hoje.month);
    final saidas = conta.saidasDoMes(hoje.year, hoje.month);
    final saldo = conta.saldoDoMes(hoje.year, hoje.month);
    final uso = entradas > 0 ? (saidas / entradas).clamp(0.0, 1.0).toDouble() : 0.0;
    final corStatus = ocultarValores
        ? AppColors.primaryLight
        : uso < 0.55
            ? AppColors.income
            : uso < 0.85
                ? AppColors.warning
                : AppColors.expense;
    final statusTxt = ocultarValores
        ? 'Resumo oculto'
        : uso < 0.55
            ? 'Ótimo controle'
            : uso < 0.85
                ? 'Atenção nos gastos'
                : 'Revise as despesas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumo do mês',
                  style: GoogleFonts.interTight(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusTxt,
                    style: GoogleFonts.interTight(
                      color: corStatus,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ocultarValores ? 0.0 : uso),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFEAF0FA),
                  valueColor: AlwaysStoppedAnimation<Color>(corStatus),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ocultarValores
                  ? 'Valores ocultos'
                  : '${(uso * 100).toStringAsFixed(0)}% das entradas gastas este mês',
              style: GoogleFonts.interTight(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricaTile(
                    label: 'Entradas',
                    valor: ocultarValores ? '•••' : formatarMoeda(entradas),
                    cor: AppColors.income,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricaTile(
                    label: 'Saídas',
                    valor: ocultarValores ? '•••' : formatarMoeda(saidas),
                    cor: AppColors.expense,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricaTile(
                    label: 'Saldo',
                    valor: ocultarValores ? '•••' : formatarMoeda(saldo),
                    cor: ocultarValores
                        ? AppColors.primaryLight
                        : saldo >= 0
                            ? AppColors.primaryLight
                            : AppColors.expense,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniGrafico(ContaState conta, DateTime hoje) {
    final entradas = conta.totaisDiariosDoMes(hoje.year, hoje.month, TipoMovimentacao.entrada);
    final saidas = conta.totaisDiariosDoMes(hoje.year, hoje.month, TipoMovimentacao.saida);
    final ultimoDia = DateTime(hoje.year, hoje.month + 1, 0).day;
    if (entradas.isEmpty && saidas.isEmpty) return const SizedBox.shrink();

    var maxY = 0.0;
    for (final v in [...entradas.values, ...saidas.values]) {
      if (v > maxY) maxY = v;
    }
    maxY = maxY <= 0 ? 100 : maxY * 1.35;

    final grupos = List.generate(ultimoDia, (i) {
      final dia = i + 1;
      final eVal = entradas[dia] ?? 0;
      final sVal = saidas[dia] ?? 0;
      return BarChartGroupData(
        x: dia,
        barsSpace: 2,
        barRods: [
          BarChartRodData(
            toY: eVal,
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF00A876), Color(0xFF00FFB3)],
            ),
            width: 5,
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
            width: 5,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF060F1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
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
                    'Fluxo diário — ${nomeMes(hoje)}',
                    style: GoogleFonts.interTight(
                      color: AppColors.textPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const _Legenda(cor: Color(0xFF00FFB3), texto: 'Entrada'),
                const SizedBox(width: 10),
                const _Legenda(cor: Color(0xFFFF7070), texto: 'Saída'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxY,
                  minY: 0,
                  barGroups: grupos,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderDark.withValues(alpha: 0.5),
                      strokeWidth: 0.5,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (v, _) {
                          if (v == 0) return const SizedBox.shrink();
                          final label = v >= 1000
                              ? 'R\$${(v / 1000).toStringAsFixed(0)}k'
                              : 'R\$${v.toStringAsFixed(0)}';
                          return Text(
                            label,
                            style: GoogleFonts.interTight(
                              color: AppColors.textSecondaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final d = v.toInt();
                          if (d == 1 || d == ultimoDia || d % 10 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '$d',
                                style: GoogleFonts.interTight(
                                  color: AppColors.textSecondaryDark,
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
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => const Color(0xFF0D1B2E),
                      getTooltipItem: (g, _, rod, ri) => BarTooltipItem(
                        '${ri == 0 ? "⬇ Entrada" : "⬆ Saída"}\n${formatarMoeda(rod.toY)}',
                        GoogleFonts.interTight(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalhoUltimas(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Últimos lançamentos',
                  style: GoogleFonts.interTight(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Movimentos mais recentes',
                  style: GoogleFonts.interTight(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, color: context.accent, size: 38),
            const SizedBox(height: 12),
            Text(
              'Nenhum lançamento ainda',
              style: GoogleFonts.interTight(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use o botão + para adicionar.',
              style: GoogleFonts.interTight(color: context.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Private widgets ──────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.textSecondaryDark : AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SaldoMetrica extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color cor;
  final bool alignEnd;

  const _SaldoMetrica({
    required this.label,
    required this.valor,
    required this.icon,
    required this.cor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: alignEnd ? 16 : 0, right: alignEnd ? 0 : 16),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(icon, color: cor, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
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

class _AcaoBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color cor;
  final bool isDark;
  final VoidCallback onTap;

  const _AcaoBtn({
    required this.label,
    required this.icon,
    required this.cor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cor, size: 22),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  label,
                  style: GoogleFonts.interTight(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricaTile extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final bool isDark;

  const _MetricaTile({
    required this.label,
    required this.valor,
    required this.cor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.interTight(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: GoogleFonts.interTight(
                color: cor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;
  const _Legenda({required this.cor, required this.texto});

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
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
