import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/cotacao_service.dart';

class TelaCotacoes extends StatefulWidget {
  const TelaCotacoes({super.key});

  @override
  State<TelaCotacoes> createState() => _TelaCotacoesState();
}

class _TelaCotacoesState extends State<TelaCotacoes>
    with AutomaticKeepAliveClientMixin {
  final _service = CotacaoService();
  List<({Cotacao cotacao, String emoji})> _cotacoes = [];
  bool _loading = true;
  String? _erro;
  DateTime? _ultimaAtualizacao;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final resultado = await _service.buscarCotacoes();
      if (mounted) {
        setState(() {
          _cotacoes = resultado;
          _loading = false;
          _ultimaAtualizacao = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() { _erro = 'Sem conexão com a internet.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregar,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDark, textPrimary, textSecondary)),
              SliverToBoxAdapter(child: _buildDestaque(isDark, textPrimary, textSecondary)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Todas as cotações',
                    style: GoogleFonts.interTight(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_loading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _shimmerTile(isDark),
                    childCount: 5,
                  ),
                )
              else if (_erro != null)
                SliverToBoxAdapter(child: _buildErro())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildTile(_cotacoes[i], isDark, textPrimary, textSecondary),
                    childCount: _cotacoes.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    final hora = _ultimaAtualizacao != null
        ? 'Atualizado às ${_ultimaAtualizacao!.hour.toString().padLeft(2, '0')}:${_ultimaAtualizacao!.minute.toString().padLeft(2, '0')}'
        : 'Puxe para atualizar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cotações',
                  style: GoogleFonts.interTight(
                    color: textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  hora,
                  style: GoogleFonts.interTight(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _carregar,
            icon: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDestaque(bool isDark, Color textPrimary, Color textSecondary) {
    if (_loading || _cotacoes.isEmpty) return const SizedBox(height: 16);

    final dolar = _cotacoes.firstWhere(
      (c) => c.cotacao.nome.contains('lar') || c.cotacao.nome == 'Dólar',
      orElse: () => _cotacoes.first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientPrimary,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dolar.emoji} ${dolar.cotacao.nome}',
                  style: GoogleFonts.interTight(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${dolar.cotacao.bid.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      dolar.cotacao.isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: dolar.cotacao.isPositive ? const Color(0xFF00E5A0) : const Color(0xFFFF6B6B),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dolar.cotacao.isPositive ? '+' : ''}${dolar.cotacao.pctChange.toStringAsFixed(2)}% hoje',
                      style: GoogleFonts.interTight(
                        color: dolar.cotacao.isPositive ? const Color(0xFF00E5A0) : const Color(0xFFFF6B6B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Máx',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                ),
                Text(
                  'R\$ ${dolar.cotacao.high.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mín',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                ),
                Text(
                  'R\$ ${dolar.cotacao.low.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    ({Cotacao cotacao, String emoji}) item,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final c = item.cotacao;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cor = c.isPositive ? AppColors.income : AppColors.expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nome,
                    style: GoogleFonts.interTight(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Máx ${c.high.toStringAsFixed(2).replaceAll('.', ',')}  •  Mín ${c.low.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.interTight(
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${c.bid.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.interTight(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      c.isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                      color: cor,
                      size: 18,
                    ),
                    Text(
                      '${c.isPositive ? '+' : ''}${c.pctChange.toStringAsFixed(2)}%',
                      style: GoogleFonts.interTight(
                        color: cor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerTile(bool isDark) {
    final base = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErro() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.expense),
          const SizedBox(height: 12),
          Text(_erro!, style: GoogleFonts.interTight(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
